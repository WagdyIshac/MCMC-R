import pandas as pd
import pyodbc

sql_conn = pyodbc.connect('DRIVER={ODBC Driver 13 for SQL Server};SERVER=azwvmapot0003.database.windows.net;DATABASE=AZSDWAPOT0002;Trusted_Connection=yes;USERNAME=wagdy2;PASSWORD=M!cr0s0ftM!cr0s0ft') 
query = "SELECT * from sys.tables"
df = pd.read_sql(query, sql_conn)

df.head(3)