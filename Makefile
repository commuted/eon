# epistemic-ontology.net
#
#   make            build the site into site/
#   make serve      build and preview on http://localhost:8000
#   make stage      refresh ontology-dist/ from the source repos, then build
#   make check      build and verify links, staging and namespaces
#   make fresh      check that site/ matches its sources (fails if stale)
#   make deploy     build, check, then rsync to the server
#
# The source repos are only needed for `make stage`. Everything else builds
# from ontology-dist/, so the site can be rebuilt from a clean checkout.

PYTHON      ?= python3
PORT        ?= 8000
RECORD_SRC  ?= $(HOME)/claude/record-ontology
HARM_SRC    ?= $(HOME)/claude/record-harm-ontology

# Deploy target. Override on the command line or in the environment, e.g.
#   make deploy DEPLOY_HOST=ec2-user@35.175.8.34 SSH_KEY=~/.ssh/lightsail-ontology.pem
DEPLOY_HOST ?= ec2-user@35.175.8.34
DEPLOY_PATH ?= /var/www/html
SSH_KEY     ?= $(HOME)/.ssh/lightsail-ontology.pem
STAGING_DIR ?= /home/ec2-user/site

.PHONY: all build serve stage check fresh deploy icons install clean help

all: build

build:
	@$(PYTHON) build.py

serve:
	@$(PYTHON) build.py --serve --port $(PORT)

check:
	@$(PYTHON) build.py --check

# Refresh the hosted serializations from the source repositories.
#   stage-record.sh copies (born permanent -- nothing to rewrite)
#   migrate.sh      rewrites example.org -> epistemic-ontology.net, and fails
#                   if any placeholder IRI survives
stage:
	@./stage-record.sh $(RECORD_SRC)
	@./migrate.sh $(HARM_SRC)
	@$(PYTHON) build.py --check

# site/ is committed so the served bytes are reviewable and deployable without
# a Python environment. This target proves it is not stale.
fresh: build
	@git diff --quiet --exit-code -- site \
	  && echo "site/ is up to date with its sources" \
	  || { echo "error: site/ is stale -- commit the rebuild"; git diff --stat -- site; exit 1; }

deploy: check
	@echo "Deploying to $(DEPLOY_HOST):$(DEPLOY_PATH)"
	rsync -avz --delete -e "ssh -i $(SSH_KEY)" site/ $(DEPLOY_HOST):$(STAGING_DIR)/
	ssh -i $(SSH_KEY) $(DEPLOY_HOST) '\
	  sudo rsync -a --delete $(STAGING_DIR)/ $(DEPLOY_PATH)/ && \
	  sudo chown -R nginx:nginx $(DEPLOY_PATH) && \
	  sudo find $(DEPLOY_PATH) -type d -exec chmod 755 {} + && \
	  sudo find $(DEPLOY_PATH) -type f -exec chmod 644 {} + && \
	  sudo nginx -t && sudo systemctl reload nginx'
	@echo "Deployed. Verify:  curl -sI -H 'Accept: text/turtle' https://epistemic-ontology.net/record"

icons:
	@./make-icons.sh
	@$(PYTHON) build.py

install:
	@$(PYTHON) -m pip install -r requirements.txt

clean:
	@rm -rf site
	@echo "removed site/"

help:
	@sed -n '2,10p' Makefile
