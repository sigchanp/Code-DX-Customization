#!/usr/bin/env python
# coding: utf-8

# In[19]:


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


# In[30]:


# filter for findings
data = { 'filter':{} }
  
r = requests.post(url=API_Base+'api/projects/'+project_contexts+'/findings/count', json=data, headers=headers)
  
# extracting findings count
findings_cnt = r.json()['count']
print(findings_cnt)


# In[4]:


import math

# compute pagination
per_page = 50
page_cnt = math.ceil(findings_cnt / per_page)
page_cnt


# In[5]:


# helper for CVSS casting
def safe_cvss_float(v):
    try:
        return float(v['CVSS v3'])
    except (ValueError, TypeError, KeyError):
        return -1.0


# In[6]:


# override default severity by CVSS scores
def severity_override(page, perPage, project_contexts):
    params = {'expand': ['results.metadata']}

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
    
    for f in findings_json:
        org_severity = f['severity']['name']
        #print(org_severity)
        max_cvss = -99.0
        for r in f['results']:
            cvss = safe_cvss_float(r['metadata'])
            if cvss > max_cvss:
                max_cvss = cvss
        sev='nocvss'
        if max_cvss > 9.7:
            sev = 'Critical'
        elif max_cvss > 8.9:
            sev = 'High'
        elif max_cvss > 5.9:
            sev = 'Medium'
        elif max_cvss >=0:
            sev = 'Low'
        #print(max_cvss)
        #print(sev)
        if max_cvss >=0:
            if org_severity != sev:
                # Override Severity
                data = {'severity':sev}
                r = requests.put(url=API_Base+'x/projects/'+project_contexts+'/findings/'+str(f['id'])+'/severity-override', json=data, headers=headers)

                # Add a comment of the change
                data = {'content':'Detected CVSS score being '+str(max_cvss)+', Severity overriden from '+org_severity+' to '+sev}
                r = requests.post(url=API_Base+'x/projects/'+project_contexts+'/findings/'+str(f['id'])+'/comment', json=data, headers=headers)
                
                print('Finding ID '+str(f['id'])+': Detected CVSS score being '+str(max_cvss)+', Severity overriden from '+org_severity+' to '+sev)


# In[7]:


for i in range(page_cnt):
    print("Working on the "+str(i+1)+" th page of findings")
    severity_override(i+1, per_page, project_contexts)


# In[ ]:




