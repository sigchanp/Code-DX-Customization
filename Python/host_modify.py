#!/usr/bin/env python
# coding: utf-8

# In[89]:


# importing the requests library
import requests
import json
import argparse
  
argParser = argparse.ArgumentParser()
argParser.add_argument("-s", "--server")
argParser.add_argument("-k", "--apikey")
argParser.add_argument("-p", "--project")

args = argParser.parse_args(['-s','http://localhost:8888/codedx/','-k','api-key:TK7bEOXw66FiX5_dVrabcdefgOgDV9WjPQ0gVESM','-p','41'])
API_Base = args.server
project_contexts = args.project

headers = {'API-Key': args.apikey,'content-type': 'application/json'}


# In[90]:


r = requests.get(url=API_Base+'x/host-scopes/all', headers=headers)

# extracting host_scopes
host_scopes = r.json()

hid = -1

for h in host_scopes:
    if h['name']=='demo':
        hid = h['id']
        break
print(hid)


# In[67]:


r = requests.get(url=API_Base+'x/hosts/'+str(hid)+'/all', headers=headers)

# extracting host_scopes
hosts = r.json()


# In[68]:


import pandas as pd
import ipaddress as ip

df = pd.DataFrame(hosts)
df.head()


# In[73]:


def add_tag(v):
    if (ip.IPv4Address(v['IP Address'][0]) > ip.IPv4Address('97.0.0.1')) and (ip.IPv4Address(v['IP Address'][0]) < ip.IPv4Address('97.255.255.255')):
        v['Environment']=['Production']
        return v
    else:
        return


# In[69]:


def add_tag(v):
    if (ip.IPv4Address(v['IP Address'][0]) > ip.IPv4Address('192.0.0.1')) and (ip.IPv4Address(v['IP Address'][0]) < ip.IPv4Address('192.255.255.255')):
        v['Environment']=['Development']
        return v
    else:
        return


# In[74]:


df['tag']=df['values'].apply(add_tag)


# In[75]:


df1 = df.loc[df['tag'].notnull()]


# In[76]:


for index, row in df1.iterrows():
    r = requests.put(url=API_Base+'x/hosts/'+str(hid)+'/'+str(row['id']), json=row['tag'], headers=headers)
    print("Modified host "+row['displayName'])


# In[ ]:





# In[ ]:





# In[62]:


#for index, row in df.iterrows():
#    r = requests.delete(url=API_Base+'x/hosts/'+str(hid)+'/'+str(row['id']), headers=headers)


# In[86]:


params = {'expand': 'policy-violations,policy-violation-fix-by, host'}

# filter for findings
data = {
        'filter':{},
        'sort':{
            "by": "severity",
            "direction": "descending"
          },
        "pagination": {
            "page": 1,
            "perPage": 50
          }}

r = requests.post(url=API_Base+'api/projects/41/findings/table', params=params, json=data, headers=headers)
r.json()


# In[ ]:




