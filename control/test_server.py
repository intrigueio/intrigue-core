import subprocess
from flask import Flask, flash, redirect, render_template, request, session, abort, Response
import json
app = Flask(__name__)

# get queued instruction
@app.route("/api/system/scheduler/request")
def request():
    data = {
      "empty": False,
      "priority": 1,
      "id": 487775,
      "uuid": "c79f805e-fddd-4506-ae5c-d7a548a92a21",
      "collection": "slpowers",
      "status": "started",
      "created_at": "2021-07-23T20:10:46.454Z",
      "started_at": "2021-08-23T18:22:31.000Z",
      "finished_at": "null",
      "session_token": "OkfCACzHNHoJK681BcX8Cw"
  }
    response = app.response_class(
        response=json.dumps(data),
        status=200,
        mimetype='application/json'
    )
    return response

@app.route("/api/system/collections/slpowers")
def vuln11():
    data = {
      "name": "slpowers",
      "uuid": "f380cdbc-f000-4801-a353-5d6ea9c7b5a5",
      "organization_uuid": "null",
      "pretty_name": "null",
      "bootstrap": "{\"id\":\"slpowers\",\"type\":\"Intrigue::Collections::PreCollection\",\"system_config\":\"default\",\"projects\":[{\"name\":\"slpowers\",\"collection\":\"slpowers\",\"collection_uuid\":\"f380cdbc-f000-4801-a353-5d6ea9c7b5a5\",\"task_name\":\"create_entity\",\"task_options\":[],\"scan_handlers\":[],\"project_handlers\":[\"data.intrigue.io\"],\"project_options\":[],\"vulnerability_checks_enabled\":true,\"use_standard_exceptions\":false,\"allowed_namespaces\":[\"slpowers\"],\"auto_enrich\":true,\"workflow_name\":\"intrigueio_precollection\",\"workflow_definition\":{\"AwsS3Bucket\":[{\"task\":\"aws_s3_put_file\"}],\"Domain\":[{\"task\":\"dns_brute_sub\",\"options\":[{\"brute_alphanumeric_size\":0},{\"use_file\":false}]},{\"task\":\"dns_lookup_dkim\",\"options\":[{\"create_domain\":true}]},{\"task\":\"dns_morph\"},{\"task\":\"dns_recurse_spf\"},{\"task\":\"dns_transfer_zone\"},{\"task\":\"dns_recurse_spf\"},{\"task\":\"dns_search_sonar\"},{\"task\":\"dns_search_tls_cert_names\"},{\"task\":\"email_brute_gmail_glxu\"},{\"task\":\"enumerate_nameservers\"},{\"task\":\"search_crt\",\"options\":[{\"extract_patterns\":\"__seed_list__\"}]},{\"task\":\"search_certspotter\",\"options\":[{\"extract_patterns\":\"__seed_list__\"}]},{\"task\":\"search_grayhat_warfare\"},{\"task\":\"search_sublister\"},{\"task\":\"search_threatcrowd\"},{\"task\":\"search_wayback_machine\"}],\"DnsRecord\":[{\"task\":\"threat/search_opendns\"}],\"EmailAddress\":[{\"task\":\"vuln/saas_google_calendar_check\"}],\"GithubAccount\":[{\"task\":\"gitrob\"}],\"IpAddress\":[{\"task\":\"port_scan\"},{\"task\":\"search_shodan\"}],\"Nameserver\":[{\"task\":\"security_trails_nameserver_search\"}],\"NetBlock\":[{\"task\":\"masscan_scan\",\"options\":[{\"tcp_ports\":80443},{\"udp_ports\":161531900}]}],\"UniqueKeyword\":[{\"task\":\"whois_lookup\"},{\"task\":\"search_bgp\"},{\"task\":\"search_grayhat_warfare\"},{\"task\":\"saas_jira_check\"},{\"task\":\"web_account_check\"}],\"Uri\":[{\"task\":\"jarm_hash_calculator\"},{\"task\":\"uri_check_api_endpoint\"},{\"task\":\"uri_brute_generic_content\"},{\"task\":\"uri_check_subdomain_hijack\"},{\"task\":\"uri_extract_linked_hosts\",\"options\":[{\"extract_patterns\":\"__seed_list__\"}]},{\"task\":\"uri_extract_tokens\"},{\"task\":\"uri_gather_ssl_certificate\"},{\"task\":\"uri_screenshot\"}]},\"seeds\":[{\"entity\":\"Domain#slpowers.com\"}]}]}",
      "configuration": {
        "ingest": {
            "disabled_check_names": [],
            "disabled_entity_types": [],
            "persist_vulns_as_issues": False
        }
      },
      "metadata": {
        "type": "Intrigue::Collections::PreCollection",
        "naics_codes": [
            "541511"
        ],
        "name": "slpowers",
        "cname": "slpowers",
        "cid": 70690,
        "tags": [
            "relato"
        ],
        "extended": "null"
      },
      "finished_runs": []
    }
    
    response = app.response_class(
        response=json.dumps(data),
        status=200,
        mimetype='application/json'
    )
    return response

# /api/system/scheduler/runs/
@app.route("/api/system/scheduler/runs/<uuid>")
def heartbeat():
    data = {
      "success" : "false"
    }
    response = app.response_class(
        response=json.dumps(data),
        status=200,
        mimetype='application/json'
    )
    return response

if __name__ == "__main__":
    app.run(host='0.0.0.0', port=8989)
