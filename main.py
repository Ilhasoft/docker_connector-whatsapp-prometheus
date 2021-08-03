#!/usr/bin/env python
# -*- coding: utf-8 -*-

# STD
import re
import string
import logging

# 3party
from flask import Flask, render_template, request, abort, Response, redirect
import requests
from werkzeug.exceptions import BadRequest

# local

app=Flask(__name__.split('.')[0])
logging.basicConfig(level=logging.INFO)
LOG=logging.getLogger("app.py")

ALLOW=string.digits+string.ascii_letters+"_-"

@app.route('/health', methods=["GET"])
def health():
	return "OK"

match=re.compile(r'[^%s]'%ALLOW)
def datasource_is_valid(datasource):
	if match.search(datasource):
		return False
	else:
		return True

@app.route('/metrics', methods=["GET"])
def connector_whatsap():
	datasource=request.args.get('datasource')
	apikey=request.args.get('apikey')
	
	if not datasource or not datasource_is_valid(datasource):
		LOG.debug("datasource not valid")
		raise BadRequest('Missing or invalid params.')
	if not apikey:
		LOG.debug("apikey not valid")
		raise BadRequest('Missing params.')

	r=requests.get(
		f'https://{datasource}/metrics',
		params={
			'format': 'prometheus'
		},
		headers={
			'Authorization': f'Apikey {apikey}'
		},
		verify=False
	)

	headers=dict(r.raw.headers)
	def generate():
		for chunk in r.raw.stream(decode_content=False):
			yield chunk

	out=Response(generate(), headers=headers)
	out.status_code=r.status_code

	return out

