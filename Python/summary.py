#!/usr/bin/env python
# coding: utf-8

# In[1]:


# importing the requests library
import requests
import json
import argparse
import pandas as pd
  
argParser = argparse.ArgumentParser()
argParser.add_argument("-s", "--server")
argParser.add_argument("-k", "--apikey")
argParser.add_argument("-p", "--project")

args = argParser.parse_args(['-s','http://localhost:8888/codedx/','-k','api-key:TK7bEOXw66FiX5_dVrtabzJQdOgDV9WjPQ0gVESM','-p','41'])
API_Base = args.server
project_contexts = args.project

headers = {'API-Key': args.apikey,'content-type': 'application/json'}


# In[2]:


# filter for findings
data = { 'filter':{} }
  
r = requests.post(url=API_Base+'api/projects/'+project_contexts+'/findings/count', json=data, headers=headers)
  
# extracting findings count
findings_cnt = r.json()['count']
print(findings_cnt)


# In[3]:


import math

# compute pagination
per_page = 50
page_cnt = math.ceil(findings_cnt / per_page)
page_cnt


# In[115]:


from html.parser import HTMLParser
class MyHTMLParser(HTMLParser):
    save_next=False
    saved_data=[]
    def __init__(self):
        super(MyHTMLParser, self).__init__()
        self.saved_data=[]
    
    def handle_starttag(self, tag, attrs):
        if tag=='pre':
            self.save_next=True

    def handle_data(self, data):
        if self.save_next:
            self.saved_data.append(data)
            self.save_next=False
            
    def get_data(self, i):
        return self.saved_data[i]
            
def extract_results(v, i, t):
    parser = MyHTMLParser()
    try:
        parser.feed(v[0]['descriptions'][t]['content'])
        return parser.get_data(i)
    except (TypeError,IndexError):
        return None


# In[116]:


# override default severity by CVSS scores
def generate_summary(page, perPage, project_contexts):
    params = {'expand': ['host,results.descriptions,results.metadata']}

    # filter for findings
    data = {
            'filter':{},
            'sort':{
                "by": "id",
                "direction": "ascending"
              },
            "pagination": {
                "page": page,
                "perPage": perPage
              }}

    r = requests.post(url=API_Base+'api/projects/'+project_contexts+'/findings/table', params=params, json=data, headers=headers)

    # extracting findings per page
    findings_json = r.json()
    df = pd.DataFrame(findings_json)
    df1 = pd.DataFrame()
    
    df1['id'] = df['id']
    df1['severityDefault'] = df['severityDefault'].apply(lambda x:x['name'])
    df1['severity'] = df['severity'].apply(lambda x:x['name'])
    df1['NetBIOSName'] = df['hostIdentifier'].apply(lambda x:x['name'])
    df1['Plugin'] = df['results'].apply(lambda x:x[0]['metadata']['Tenable.sc Plugin ID'])
    df1['PluginName'] = df['results'].apply(lambda x:x[0]['descriptor']['name'])
    df1['PluginOutput'] = df['results'].apply(extract_results, args=(0, 'contextual'))
    df1['Description'] = df['results'].apply(extract_results, args=(0, 'general'))
    df1['Synopsis'] = df['results'].apply(extract_results, args=(1, 'general'))
    df1['Solution'] = df['results'].apply(extract_results, args=(2, 'general'))
    df1['Patch Publication'] = df['results'].apply(lambda x:x[0]['metadata']['First Discovered'])
    df1['Family'] = df['results'].apply(lambda x:x[0]['toolHierarchy'][1])
    
    return df1


# In[117]:


summary=pd.DataFrame()
for i in range(page_cnt):
    print("Working on the "+str(i+1)+" th page of findings")
    df = generate_summary(i+1, per_page, project_contexts)
    summary = summary.append(df, ignore_index=True)
print(summary.count())


# In[ ]:


summary.to_csv("summary.csv",index=False)


# In[125]:


infomap = pd.read_csv('InformationMapping.csv')
output = pd.merge(summary, infomap, how='left', left_on = 'NetBIOSName', right_on = 'DNS Name')


# In[126]:


output.to_csv("summary_output.csv",index=False)


# In[ ]:





# In[ ]:







