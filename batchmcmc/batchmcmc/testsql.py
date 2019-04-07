import pandas as pd
import pyodbc
import pymssql
import csv



def echo(text, color="", dim=False):
    try:
        click.secho(text, fg=color, dim=dim)
    except:
        print (text)

conn2 = pyodbc.connect(driver='{SQL Server Native Client 11.0}',server='tcp:azwvmapot0003.database.windows.net,1433',database='AZSDWAPOT0002', uid='wagdy2', pwd='M!cr0s0ftM!cr0s0ft')
#conn = pymssql.connect(server='azwvmapot0003.database.windows.net', user='wagdy2', password='M!cr0s0ftM!cr0s0ft', database='master')
#cursor = conn2.cursor()

#cursor.execute("SELECT * from sys.tables")
#row = cursor.fetchone()

#print(row)
#sql_conn = pyodbc.connect('DRIVER={SQL Server};SERVER=;DATABASE=;USERNAME=;PASSWORD=;') 

query = "SELECT * from sys.tables"

df = pd.read_sql(query, conn2)


with open ('simdata-timeseries-forward/202102110001.csv', 'r') as f:
    reader = csv.reader(f)
    next(reader, None)  # skip the headers
    data = next(reader) 
    #echo(data)
    query = 'insert into dbo.TimeSeriesForward3 values ({0})'
    query = query.format(','.join('?' * len(data)))
    cursor = conn2.cursor()
    cursor.execute(query, data)
    for data in reader:
        cursor.execute(query, data)
    cursor.commit()

echo("file written")
