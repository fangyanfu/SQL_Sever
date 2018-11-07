# -*- coding: utf-8 -*-
"""
Created on Sun Nov  4 13:08:54 2018

@author: fany
"""
import pandas as pd
from sqlalchemy import create_engine
import pymssql

##to save data
sci_p = pd.read_stata(r'''X:\Prof. Harhoff\Harhoff_GENERAL\PERSONEN\Z Famulanten\Fang, Yanfu\felix\patent_science_link.dta''')
engine = create_engine(r'mssql+pymssql://IP_MPG\fany:Michaelwow1!@10.0.46.2/development')
sci_p.to_sql(r'fy_pat_sci', engine)

#to read data

engine = create_engine(r'mssql+pymssql://IP_MPG\fany:Michaelwow1!@10.0.46.2/development')
sql_cmd =r'SELECT * FROM [development].[dbo].[fy_pat_sci]'
df = pd.read_sql(sql_cmd, engine)