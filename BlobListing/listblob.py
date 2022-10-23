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
backward ='simdata-timeseries-backward/'
BackwardAnn= "simdata-timeseries-Backward-Annual/"
lmBackward12= "simdata-timeseries-Backward-lmBackward12/"
lmBackward1= "simdata-timeseries-Backward-lmBackward1/"
lmBackward2= "simdata-timeseries-Backward-lmBackward2/"
forward = 'simdata-timeseries-forward'
forwardAnnual = 'simdata-timeseries-forward-Annual/'  
lmForward12=  'simdata-timeseries-forward-lmForward12/'
lmForward1='simdata-timeseries-forward-lmForward1/'
lmForward2 ='simdata-timeseries-forward-lmForward2/'

folder = lmBackward1+ids
print(folder)
generator = block_blob_service.list_blobs(container_name, prefix=folder)
print('\nList blobs in the container')
i=0
allnames =''

with open(ids+'.csv', 'a') as csvfile:
    size = 0
    for blob in generator:
        i = i+1
        blobname = re.sub(folder,'',blob.name)
        blobname = re.sub('.csv',',',blobname)
        #allnames += blobname
        size += len(blobname)
    #wr.writerow(ids)
        sys.stdout.write('Download progress: %d%%   \r' % i )
        sys.stdout.flush()
        csvfile.write(blobname)#np.savetxt('runids.csv', ids, delimiter=',', fmt='%s')
    
print('\ndata dumped')

