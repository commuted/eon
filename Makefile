# epistemic-ontology.net
#
#   make            build the site into site/
#   make serve      build and preview on http://localhost:8000
#   make stage      refresh ontology-dist/ from the source repos, then build
#   make check      build and verify links, staging and namespaces
#   make check-server  read-only health check of the DEPLOYED site
#   make fresh      check that site/ matches its sources (fails if stale)
#   make deploy     build, check, then rsync to the server (push)
#   make release    commit-and-push, then have the server pull and install
#
# The source repos are only needed for `make stage`. Everything else builds
# from ontology-dist/, so the site can be rebuilt from a clean checkout.

PYTHON      ?= python3
PORT        ?= 8000
RECORD_SRC  ?= $(HOME)/claude/record-ontology
HARM_SRC    ?= $(HOME)/claude/record-harm-ontology

# Deploy target. Real values live in deploy.env, which is gitignored -- this is
# a public repository and infrastructure specifics do not belong in it.
#   cp deploy.env.example deploy.env && $$EDITOR deploy.env
# Command-line overrides still win: make deploy DEPLOY_HOST=user@host
-include deploy.env

DEPLOY_HOST ?= $(error DEPLOY_HOST is not set -- cp deploy.env.example deploy.env)
DEPLOY_PATH ?= /var/www/html
SSH_KEY     ?= $(HOME)/.ssh/id_rsa
STAGING_DIR ?= /home/$(shell echo $(DEPLOY_HOST) | cut -d@ -f1)/site
GIT_REMOTE  ?= https://github.com/commuted/eon.git
EON_CHECKOUT ?= /opt/eon

.PHONY: all build serve stage check check-server fresh deploy release icons install clean help

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

# Read-only. Verifies the live server: nginx running/enabled, nginx -t passing,
# exactly one config loaded, live config == this repo, served tree == site/, and
# the namespace IRIs still negotiating with CORS and charset intact.
check-server:
	@./check-server.sh $(DEPLOY_HOST) $(SSH_KEY)

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
	@echo
	@$(MAKE) --no-print-directory check-server

# Pull-based deploy: the server fetches from git and installs itself. Preferred
# over `make deploy` -- the server is the one place that decides what it runs,
# it works without this workstation, and server/install.sh rolls the nginx
# config back if it fails nginx -t.
release: check fresh
	@git push origin HEAD
	@ssh -i $(SSH_KEY) $(DEPLOY_HOST) '$(EON_CHECKOUT)/server/install.sh'

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
