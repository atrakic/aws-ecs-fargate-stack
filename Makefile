MAKEFLAGS += --silent

BASEDIR=$(shell git rev-parse --show-toplevel)

APP ?= publisher

.PHONY: all terraform test gotest docker healthcheck clean

all: docker terraform test

%:
	docker compose up --build --force-recreate --no-color $@ -d

docker:
	docker compose up --build --no-deps --remove-orphans -d
	while ! \
	[[ "$$(docker inspect --format "{{json .State.Health }}" $(APP) | jq -r ".Status")" == "healthy" ]];\
	do \
		echo "waiting for $(APP) ..."; \
		sleep 1; \
	done
	docker inspect localstack --format "{{.State.Status}}" | grep -q running || exit 1
	curl --connect-timeout 5 --retry 5 --retry-delay 0 --retry-max-time 60 http://localhost:8000/

healthcheck:
	docker inspect $(APP) --format "{{ (index (.State.Health.Log) 0).Output }}"

terraform:
	${BASEDIR}/scripts/terraform.sh

test:
	export $(shell cat .env | grep -v ^# | xargs)
	DEPLOYMENT_ENVIRONMENT=true ${BASEDIR}/scripts/terraform.sh
	${BASEDIR}/tests/test.sh
	pytest -v

gotest: _pre
	pushd tests; go test ./... -v; popd

_pre:
	cp -f ${BASEDIR}/tests/fixtures/localstack/versions.tf ${BASEDIR}/terraform/versions.tf
	cp -f ${BASEDIR}/tests/fixtures/fixtures.tfvars ${BASEDIR}/terraform/fixtures.tfvars

clean:
	# Skip terraform destroy for now
	##${BASEDIR}/scripts/terraform.sh clean
	rm -rf ${BASEDIR}/terraform/terraform.tfstate*
	rm -rf ${BASEDIR}/terraform/*.tfplan
	#rm -rf ${BASEDIR}/terraform/.terraform
	rm -rf ${BASEDIR}/terraform/fixtures.tfvars
	git checkout ${BASEDIR}/terraform/versions.tf
	docker compose down --remove-orphans -v --rmi local

-include .env include.mk
