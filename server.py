#!/usr/bin/python
# -*- coding: utf-8 -*-

import uuid
from flask import Flask, flash, redirect, render_template, request, \
    session, abort, Response, make_response, url_for, send_file
from flask_api import status
app = Flask(__name__)

@app.route('/ruclei')
def ruclei():
	return ("dc9983e7e2d54e1f87e480204fa8ad56")

@app.route('/authenticated-endpoint')
def authenticated():
	return ("Ruclei rocks")

@app.route('/Caterpillar')
def caterpillar():
	return ("hit me with your best shot")

@app.route('/Alice')
def alice():
	return ("FRIDAY")

@app.route('/at')
def moneyfornothing():
	return ("dire straits")

@app.route('/jkstatus')
def sultanswings():
	resp = Response("JK Status Manager", headers={'WWW-Authenticate': ['Test', 'NTLM TlRMTVNTUAACAAAABAAEADgAAAAFgokCLJYO/nfpi/IAAAAAAAAAAOgA6AA8AAAABgOAJQAAAA9PAFIAAgAEAE8AUgABABQATQBTAEcATABBAEIATwBGAEYAMgAEADIAbwByAC4AcAByAG8AdgBpAGQAZQBuAGMAZQBtAHMAZwBsAGEAYgAuAGwAbwBjAGEAbAADAEgATQBzAGcATABhAGIATwBmAGYAMgAuAG8AcgAuAHAAcgBvAHYAaQBkAGUAbgBjAGUAbQBzAGcAbABhAGIALgBsAG8AYwBhAGwABQAyAGEAZAAuAHAAcgBvAHYAaQBkAGUAbgBjAGUAbQBzAGcAbABhAGIALgBsAG8AYwBhAGwABwAIAFByQvGKAdcBAAAAAA==']})
	return resp

@app.route('/abs/')
def abs():
	return Response("{'a':'b'}", status=401, headers={'WWW-Authenticate': 'NTLM TlRMTVNTUAACAAAABAAEADgAAAAFgokCLJYO/nfpi/IAAAAAAAAAAOgA6AA8AAAABgOAJQAAAA9PAFIAAgAEAE8AUgABABQATQBTAEcATABBAEIATwBGAEYAMgAEADIAbwByAC4AcAByAG8AdgBpAGQAZQBuAGMAZQBtAHMAZwBsAGEAYgAuAGwAbwBjAGEAbAADAEgATQBzAGcATABhAGIATwBmAGYAMgAuAG8AcgAuAHAAcgBvAHYAaQBkAGUAbgBjAGUAbQBzAGcAbABhAGIALgBsAG8AYwBhAGwABQAyAGEAZAAuAHAAcgBvAHYAaQBkAGUAbgBjAGUAbQBzAGcAbABhAGIALgBsAG8AYwBhAGwABwAIAFByQvGKAdcBAAAAAA=='},  mimetype='application/json')
	

@app.route('/yamlstring')
def cashmoney():
  	return send_file("/Users/maxim/Desktop/ruclei-public/debug/blackjack.yaml", attachment_filename="blackjack.yaml", as_attachment=True)

@app.route('/zipfile')
def moviesandtv():
	return send_file("/tmp/a.tar.gz", attachment_filename='a.tar.gz', as_attachment=True)

@app.route('/MAXIM9999')
def rocketman3():
	return 'MAXIM1337'


@app.route('/csrftoken')
def rocketman2():
	return 'not found'

@app.route('/csrftoken2')
def rocketman():
	return '9f74af92-8a92-akf2'

@app.route('/dupheaders')
def zzztopzzz():
	resp = Response("The Caterpillar and Alice looked at each other", headers={'Server': ['Apache 1.1', 'Apache 5.4']})
	return resp
 
@app.route('/getname')
def zzztop():
	resp = Response("MAXIM9999, SHPEND, and JCRAN RANDOM WORDS abc")
	resp.headers['Server'] = 'Apache 2.2'
	return resp 

@app.route('/server2')
def fantasy():
	resp = Response("The SHPEND and JCRAN looked at each other")
	resp.headers['Server'] = 'Nginx 1.1'
	return resp 

@app.route('/getname2')
def dale():
	return "maxim2"


@app.route('/retrieveapikey')
def test1():
	return '1234234234234234adfasdf'

@app.route('/jars/upload', methods=['POST'])
def zys():
    print(request.__dict__)
    return 'works: {}'.format(request.get_data())

def alkdf():
	return "test"

@app.route('/pcidss/report', methods=['POST'])
def abc():
	return "111111111\.111111111132232332323"

@app.route('/menu/ss', methods=['GET'])
def bac():
	return "111111111\.111111111132232332323"

@app.route('/menu/neo', methods=['GET'])
def bac123():
	return "111111111\.111111111132232332323"

@app.route('/menu/stc', methods=['GET'])
def bac12345():
	return "111111111\.111111111132232332323"

@app.route('/adslfkjalsdfkjasldkf')
def redirectme():
	return redirect(url_for('setcookie'))

@app.route('/logupload', methods=['POST'])
def adsfsdfsdf():
	print(request.get_data())
	return 'works: {}'.format(request.get_data())

@app.route('/xim')
def testing12345():
	return "test"
@app.route('/setcookie')
def setcookie():
    resp = make_response()
    resp.set_cookie('BIGipServerWeb-pool-001', '60038316.20480.0000')
    resp.set_cookie('username', 'maxim')
    return resp

@app.route('/')
def apache():
	resp = Response()
	resp.headers['Server'] = 'Microsoft-IIS/7.5'
	return resp

@app.route('/getcookie')
def getcookie():
    value = request.cookies.get('username')
    if value:
        return value
    else:
        return 'no cookie'
if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8008)
