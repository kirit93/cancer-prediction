import argparse
import json
import logging
import os
import sys
import torch
import torch.distributed as dist
import torch.nn as nn
import torch.nn.functional as F
import torch.optim as optim
import torch.utils.data
import torch.utils.data.distributed
import torchvision
from torch.utils.data import Dataset, DataLoader
from torchvision import transforms
from PIL import Image

logger = logging.getLogger(__name__)
logger.setLevel(logging.DEBUG)
logger.addHandler(logging.StreamHandler(sys.stdout))

class ImageDataset(Dataset):
    """ """
    def __init__(self, root = None, transform = None):
        ''' '''
        # root path must be provided
        assert not root is None

        self.files = [obj for obj in os.listdir(path) if obj[-3:] == 'png']
        self.transform = transform

    def __len__(self):
        ''' '''
        return len(self.files)
    
    def __getitem__(self, idx):
        ''' '''
        image = self.files[idx]
    
        # we may infer the label from the filename
        # this logic will change based on incoming data
        label = image.split('-label-')[-1]
        image = Image.open(image)
        
        if self.transform:
            image = self.transform(image)
        
        return {'image' : image, 'label' : label}


# Simple multilayer CNN
class Net(nn.Module):
    """ """
    def __init__(self):
        ''' '''
        super(Net, self).__init__()
        self.conv1 = nn.Conv2d(3, 10, kernel_size=5)
        self.conv2 = nn.Conv2d(10, 20, kernel_size=5)
        self.conv2_drop = nn.Dropout2d()
        self.fc1 = nn.Linear(312500, 320)
        self.fc2 = nn.Linear(320, 50)
        self.fc3 = nn.Linear(50, 2)

    def forward(self, x):
        ''' '''
        # Max pooling over a (2, 2) window
        x = F.max_pool2d(F.relu(self.conv1(x)), (2, 2))
        # If the size is a square you can only specify a single number
        x = F.max_pool2d(F.relu(self.conv2(x)), 2)
        x = x.view(-1, self.num_flat_features(x))
        x = F.relu(self.fc1(x))
        x = F.relu(self.fc2(x))
        x = self.fc3(x)
        return F.log_softmax(x, dim=1)
    
    def num_flat_features(self, x):
        ''' '''
        size = x.size()[1:]  # all dimensions except the batch dimension
        num_features = 1
        for s in size:
            num_features *= s
        return num_features
        
def _get_train_data_loader(train_batch_size, dataset, is_distributed, **kwargs):
    ''' '''
    logger.info("Get train data loader")
    train_sampler = torch.utils.data.distributed.DistributedSampler(dataset) if is_distributed else None
    return torch.utils.data.DataLoader\
    (
        dataset, 
        batch_size = train_batch_size, 
        shuffle = train_sampler is None, 
        sampler = train_sampler, 
        **kwargs
    )


def _get_test_data_loader(test_batch_size, dataset, **kwargs):
    ''' '''
    logger.info("Get test data loader")
    return torch.utils.data.DataLoader\
    (
        dataset,
        batch_size = test_batch_size, 
        shuffle = True, 
        **kwargs
    )


def _average_gradients(model):
    ''' '''
    # Gradient averaging.
    size = float(dist.get_world_size())
    for param in model.parameters():
        dist.all_reduce(param.grad.data, op=dist.reduce_op.SUM)
        param.grad.data /= size


def train(args):
    ''' '''
    is_distributed = len(args.hosts) > 1 and args.backend is not None
    logger.debug("Distributed training - {}".format(is_distributed))
    
    use_cuda = args.num_gpus > 0
    logger.debug("Number of gpus available - {}".format(args.num_gpus))
    
    kwargs = {'num_workers': 1, 'pin_memory': True} if use_cuda else {}
    device = torch.device("cuda" if use_cuda else "cpu")
    
    if is_distributed:
        # Initialize the distributed environment.
        world_size = len(args.hosts)
        os.environ['WORLD_SIZE'] = str(world_size)
        host_rank = args.hosts.index(args.current_host)
        os.environ['RANK'] = str(host_rank)
        dist.init_process_group(backend=args.backend, rank=host_rank, world_size=world_size)
        
        logger.info\
        (
            'Initialized the distributed environment: \'{}\' backend on {} nodes. '.format\
            (
                args.backend,
                dist.get_world_size()
            ) + 'Current host rank is {}. Number of gpus: {}'.format\
            (
                dist.get_rank(), 
                args.num_gpus
            )
        )

    # set the seed for generating random numbers
    torch.manual_seed(args.seed)
    if use_cuda:
        torch.cuda.manual_seed(args.seed)
        
    # Optionally transform image to grayscale if needed
    # Add this to Compose - transforms.Grayscale(num_output_channels = 1)
    transform = transforms.Compose([
        transforms.ToTensor(), 
        transforms.Normalize((0.5, 0.5, 0.5), (0.5, 0.5, 0.5))]
    )

    # Create folder structure such as train/label1, train/label2 etc.
    # For scalability, this will be swapped out with a custom implemented 
    # Dataset - <module ImageDataset> implemented above.
    
    # train_dataset = ImageDataset\
    # (
    #     root = args.train_dir, 
    #     transform = transform
    # )
    
    # test_dataset = ImageDataset\
    # (
    #     root = args.train_dir, 
    #     transform = transform
    # )

    train_dataset = torchvision.datasets.ImageFolder\
    (
        root = args.train_dir,
        transform = transform
    )
    
    test_dataset = torchvision.datasets.ImageFolder\
    (
        root = args.test_dir,
        transform = transform
    )
    print("Length of train dataset - ", len(train_dataset))
    print("Length of test dataset - ", len(test_dataset))
    
    train_loader = _get_train_data_loader(args.train_batch_size, train_dataset, is_distributed, **kwargs)
    test_loader = _get_test_data_loader(args.test_batch_size, test_dataset, **kwargs)

    logger.debug\
    (
        "Processes {}/{} ({:.0f}%) of train data".format\
        (
            len(train_loader.sampler), 
            len(train_loader.dataset),
            100. * len(train_loader.sampler) / len(train_loader.dataset)
        )
    )

    logger.debug\
    (
        "Processes {}/{} ({:.0f}%) of test data".format\
        (
            len(test_loader.sampler), 
            len(test_loader.dataset),
            100. * len(test_loader.sampler) / len(test_loader.dataset)
        )
    )

    model = Net().to(device)
    if is_distributed and use_cuda:
        # multi-machine multi-gpu case
        model = torch.nn.parallel.DistributedDataParallel(model)
    else:
        # single-machine multi-gpu case or single-machine or multi-machine cpu case
        model = torch.nn.DataParallel(model)
       
    logger.debug("Starting to train")

    optimizer = optim.SGD(model.parameters(), lr=args.lr, momentum=args.momentum)

    logger.debug("Created optimizer")
    
    for epoch in range(1, args.epochs + 1):
        model.train()
        logger.debug("Train command called.")

        for batch_idx, (data, target) in enumerate(train_loader, 1):
            logger.info("Target - {}".format(target))
            data, target = data.to(device), target.to(device)
            optimizer.zero_grad()
            output = model(data)
            loss = F.nll_loss(output, target)
            loss.backward()

            if is_distributed and not use_cuda:
                # average gradients manually for multi-machine cpu case only
                _average_gradients(model)

            optimizer.step()
            if batch_idx % args.log_interval == 0:
                logger.info\
                (
                    'Train Epoch: {} [{}/{} ({:.0f}%)] Loss: {:.6f}'.format\
                    (
                        epoch, 
                        batch_idx * len(data), 
                        len(train_loader.sampler),
                        100. * batch_idx / len(train_loader), loss.item()
                    )
                )
        test(model, test_loader, device)

    save_model(model, args.model_dir)

def test(model, test_loader, device):
    ''' '''
    model.eval()
    test_loss = 0
    correct = 0
    with torch.no_grad():
        for data, target in test_loader:
            data, target = data.to(device), target.to(device)
            output = model(data)
            test_loss += F.nll_loss(output, target, size_average=False).item()  # sum up batch loss
            pred = output.max(1, keepdim=True)[1]  # get the index of the max log-probability
            correct += pred.eq(target.view_as(pred)).sum().item()

    test_loss /= len(test_loader.dataset)
    logger.info\
    (
        'Test set: Average loss: {:.4f}, Accuracy: {}/{} ({:.0f}%)\n'.format\
        (
            test_loss, 
            correct, 
            len(test_loader.dataset),
            100. * correct / len(test_loader.dataset)
        )
    )


def model_fn(model_dir):
    ''' '''
    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    model = torch.nn.DataParallel(Net())
    with open(os.path.join(model_dir, 'model.pth'), 'rb') as f:
        model.load_state_dict(torch.load(f))
    return model.to(device)


def save_model(model, model_dir):
    ''' '''
    logger.info("Saving the model.")
    path = os.path.join(model_dir, 'model.pth')
    # recommended way from http://pytorch.org/docs/master/notes/serialization.html
    torch.save(model.cpu().state_dict(), path)

if __name__ == '__main__':
    ''' '''
    parser = argparse.ArgumentParser()

    # Data and model checkpoints directories
    parser.add_argument('--train-batch-size', type=int, default=1000, metavar='N',
                        help='input batch size for training (default: 1000)')
    parser.add_argument('--test-batch-size', type=int, default=1000, metavar='N',
                        help='input batch size for testing (default: 1000)')
    parser.add_argument('--epochs', type=int, default=10, metavar='N',
                        help='number of epochs to train (default: 10)')
    parser.add_argument('--lr', type=float, default=0.01, metavar='LR',
                        help='learning rate (default: 0.01)')
    parser.add_argument('--momentum', type=float, default=0.5, metavar='M',
                        help='SGD momentum (default: 0.5)')
    parser.add_argument('--seed', type=int, default=1, metavar='S',
                        help='random seed (default: 1)')
    parser.add_argument('--log-interval', type=int, default=100, metavar='N',
                        help='how many batches to wait before logging training status')
    parser.add_argument('--backend', type=str, default=None,
                        help='backend for distributed training (tcp, gloo on cpu and gloo, nccl on gpu)')

    # Container environment
    parser.add_argument('--hosts', type=list, default=json.loads(os.environ['SM_HOSTS']))
    parser.add_argument('--current-host', type=str, default=os.environ['SM_CURRENT_HOST'])
    parser.add_argument('--model-dir', type=str, default=os.environ['SM_MODEL_DIR'])
    parser.add_argument('--train-dir', type=str, default=os.environ['SM_CHANNEL_TRAIN'])
    parser.add_argument('--test-dir', type=str, default=os.environ['SM_CHANNEL_TEST'])
    parser.add_argument('--num-gpus', type=int, default=os.environ['SM_NUM_GPUS'])

    train(parser.parse_args())