# Secrets YAML Test Script

1. Deploy openfaas with secrets on docker swarm:
  ```
  $ git clone https://github.com/lucasroesler/faas/ -b feature-secured-secrets
  $ cd faas
  $ # In docker-compose.yml, rename gateway image to something like <yourDockerHubID>/gateway:secrets01
  $ ./deploy_stack.sh
  ```
2. Build my PR version of `faas-cli`:
  ```
  $ git clone https://github.com/ericstoekl/faas-cli/ -b secretsYamlMerge
  $ cd faas-cli
  $ ./build.sh
  $ # Move ./faas-cli binary to your binpath
  ```
3. Run `./test.bash` from this directory
