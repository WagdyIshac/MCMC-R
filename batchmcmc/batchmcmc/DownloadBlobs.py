import os, uuid, sys, re, csv
from azure.storage.blob import BlockBlobService, PublicAccess
import numpy as np
# Create the BlockBlockService that is used to call the Blob service for the storage account
#block_blob_service = BlockBlobService(account_name='adiamcmc2', account_key='YoiUZ+Glq4ucvFUygia6NgPe58v2cdTyv0DW0sD3VG5Eu6BdcLazwLIFaExX5JtjQS7lMWuKvWwX31z/SWNURw==') 
block_blob_service = BlockBlobService(account_name='azstaapot0001', account_key='nyWm/IFK07ddzadq9f2gKTq4OvBrq4UMxXn4jWzbSw/3GOkHzR3K/qH6Gp0brGf8F9b7j0bvS3+ia653AAeoiA==') 
# Create a container called 'quickstartblobs'.
container_name ='simdata'
#block_blob_service.create_container(container_name) 

# Set the permission so the blobs are public.
#block_blob_service.set_container_acl(container_name, public_access=PublicAccess.Container)
ids = sys.argv[1]
referencefolders =['simdata-timeseries-backward/','simdata-timeseries-Backward-Annual/','simdata-timeseries-Backward-lmBackward12/','simdata-timeseries-Backward-lmBackward1/','simdata-timeseries-Backward-lmBackward2/', 'simdata-timeseries-forward', 'simdata-timeseries-forward-Annual/'  , 'simdata-timeseries-forward-lmForward12/', 'simdata-timeseries-forward-lmForward1/','simdata-timeseries-forward-lmForward2/']
local_path = "C:\Code\mcmc\BlobListing\\"
for refF in referencefolders:
    foldername = refF + ids
    directory = os.path.dirname(foldername)
    if not os.path.exists(directory):
        os.makedirs(directory)
    generator = block_blob_service.list_blobs(container_name, prefix=foldername)
    print('\nList blobs in the container '+foldername)
    i=0
    allnames ='' 
    for blob in generator:
        print('\n' +blob.name)
        i = i+1
        new_path = local_path+re.sub('/','\\\\',refF)
        blobname = re.sub(refF,'',blob.name)
        full_path_to_file2 = os.path.join(new_path, blobname )
        print('\n full_path_to_file2 name ' +full_path_to_file2)
        block_blob_service.get_blob_to_path(container_name, blob.name, full_path_to_file2)
        print('\n' +full_path_to_file2)
        #blobname = re.sub(folder,'',blob.name)
        #blobname = re.sub('.csv',',',blobname)
        #allnames += blobname
        
    #wr.writerow(ids)
        sys.stdout.write('Download progress: %d%%   \r' % i )
        sys.stdout.flush()
           
        
print('\ndata dumped')

