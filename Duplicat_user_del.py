import requests
import urllib3
import pandas as pd
import json

urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)
data1 = pd.read_csv("Person_2022.csv", sep=",", encoding="latin-1")
id_without_request = []
id_with_request = []
id_without_inc = []
id_with_inc = []
final_list = []
for i, row1 in data1[:].iterrows():
    id = row1["Id"]
    auth_url = "https://dev-acta-bddf.fr.socgen/auth/authentication-endpoint/authenticate/token?TENANTID=310356934"
    auth_headers = {
        "Content-Type": "application/json"
    }
    auth_body = "{\"Login\":\"chaya.doddaiah-ext@socgen.com\",\"Password\":\"Admin_1234\"}"
    res1 = requests.post(auth_url, headers=auth_headers, data=auth_body, verify=False)
    token1 = str(res1.content)
    token1 = token1.lstrip(' b')

    # For request

    url1 = f"https://dev-acta-bddf.fr.socgen/rest/310356934/ems/Request?filter=RequestedByPerson.Id eq {id} or AssignedToPerson.Id eq {id} or ClosedByPerson.Id eq {id} or RequestedForPerson.Id eq {id} or OwnedByPerson.Id eq {id} or RecordedByPerson.Id eq {id} or ResolvedByPerson.Id eq {id}&layout=Id,DisplayLabel,RequestedByPerson.Id,AssignedToPerson.Id,ClosedByPerson.Id,RequestedForPerson.Id,OwnedByPerson.Id,RecordedByPerson.Id,ResolvedByPerson.Id"
    payload = {}

    headers = {
        "Cookie": "",
        "Content-Type": "application/json"
    }
    c = "SMAX_AUTH_TOKEN="
    headers["Cookie"] = c + token1
    headers["Cookie"] = headers["Cookie"].replace("'", "")
    response1 = requests.request("GET", url=url1, headers=headers, data=payload, verify=False)
    id_dict1 = json.loads(response1.text)
    if len(id_dict1["entities"]) != 0:
        if id not in id_with_request:
            id_with_request.append(id)
    else:
        if id not in id_without_request:
            id_without_request.append(id)

    # For incident

    url2 = f"https://dev-acta-bddf.fr.socgen/rest/310356934/ems/Incident?filter=RequestedByPerson.Id eq {id} or  AssignedPerson.Id eq 56641 or ClosedByPerson.Id eq {id} or  ContactPerson.Id eq {id} or LastUpdatedByPerson.Id eq {id} or OwnedByPerson.Id eq {id} or RecordedByPerson.Id eq {id} or SolvedByPerson.Id eq {id}&layout=Id"
    payload = {}
    headers = {
        "Cookie": "",
        "Content-Type": "application/json"
    }
    c = "SMAX_AUTH_TOKEN="
    headers["Cookie"] = c + token1
    headers["Cookie"] = headers["Cookie"].replace("'", "")
    response2 = requests.request("GET", url=url2, headers=headers, data=payload, verify=False)
    id_dict = json.loads(response2.text)
    if len(id_dict["entities"]) != 0:
        if id not in id_with_inc:
            id_with_inc.append(row1["Id"])
    else:
        if id not in id_without_inc:
            id_without_inc.append(row1["Id"])

print("List with req tickets:", id_with_request)
print("List without req tickets:", id_without_request)
print("List with inc tickets:", id_with_inc)
print("List without inc tickets:", id_without_inc)

for req_id in id_without_request:
    if req_id not in id_with_inc and req_id not in id_with_request or req_id in id_without_inc:
        final_list.append(req_id)


final_list = list(dict.fromkeys(final_list))
print("This is final list", final_list)
final_list_del = pd.Series(final_list)
final_list_del.to_csv("del.csv", index=False, encoding='utf-8')
