# Momo Store Инфраструктурный репозиторий (Дипломный проект Яндекс.Практикум)
Репозиторий предназначен для хранения кода, описывающего инфраструктуру для приложения Momo Store.
Исходный код приложения лежит [здесь](https://gitlab.praktikum-services.ru/anton-alekseyev/momo-store)
## Структура репозитория
```
├── kubernetes - helm чарты для приложения и среды мониторинга
│   ├── kubeconfig-install - скрипт получения статического kubeconfig
│   ├── momo-store - helm чарт приложения Momo-store
│   └── monitoring-tools - helm чарт среды мониторинга приложения Momo-store
├── terraform
│   ├── managed-kubernetes - terraform скрипты создания кластера kubernetes в yandex cloud
│   └── object-storage - terraform скрипты создания s3 хранилища в yandex cloud
```
## Инструкция пользователя
### Создание кластера managed kubernetes
Для создания кластера kubernetes необходимо:
1. Создать S3 бакет для сохранения terraform state
2. Создать Managed Kubernetes в yandex cloud

#### Создание S3 хранилища
Yandex Object Storage позволяет организовать S3 хранилище для хранения медиа данных и состояния terraform.
Для создания s3 корзин необходимы следующие шаги:
1. Перейти в папке с terraform скриптами
```shell
cd terraform/object-storage
```
2. Создать файл `terraform.tfvars` или передать через командную строку следующие параметры:
```shell
yc_token     = <IAM- или OAuth-токен yandex client>
yc_cloud_id  = <идентификатор облака>
yc_folder_id = <идентификатор каталога>
```
3. Также можно изменить параметры в variable.tf по усмотрению
4. Выполнить terraform скрипт
```shell
terraform init
terraform plan
terraform apply
```
5. В блоке output вы получите необходимые параметры для создания backend terraform
```shell
access_key
bucket_name
secret_key
```
#### Yandex Managed Kubernetes
Yandex Managed Kubernetes позволяет создать кластер kubernetes с помощью terraform.
Для создания кластера необходимы следующие шаги:
1. Перейти в папке с terraform скриптами
```shell
cd terraform/managed-kubernetes
```
2. Создать файл `terraform.tfvars` или передать через командную строку в terraform apply следующие параметры:
```shell
yc_token     = <IAM- или OAuth-токен yandex client>
yc_cloud_id  = <идентификатор облака>
yc_folder_id = <идентификатор каталога>
```
3. Для конфигурации удаленного хранилища состояния terraform необходимо создать файл `backend.conf`
или передать через командную строку следующие параметры, полученные из пункта создание S3 хранилища
```shell
access_key
secret_key
```
4. Также можно изменить параметры в variable.tf по усмотрению (например поменять параметры мощность нодов кластера).
С текущими параметрами создаются 3 ноды кластера, каждая имеет лейбл `staging`, `production`, `infra` - что означает, одна нода
для тестового сегмента, вторая для продуктового, третья для сервисов мониторинга приложения
5. Выполнить terraform скрипт
```shell
terraform init -backend-config=backend.conf
terraform plan
terraform apply
```

В текущей сборке идентификатор кластера `catri7jto5ve5rmtde18`

### Инфраструктура кластера kubernetes
#### Конфигурирование кластера kubernetes
1. Необходимо сконфигурировать статический kubeconfig для получения доступа к кластеру с помощью kubectl.
[Туториал](https://cloud.yandex.ru/docs/managed-kubernetes/operations/connect/create-static-conf)
   1. Перейти в папку kubernetes/kubeconfig-install
   2. Инициализировать yc
   3. Запустить скрипт create_kubeconfig.sh
    ```shell
    bash create_kubeconfig.sh
    ```
   4. Полученные kube.config и ca.pem можно использовать в дальнейшем при построении CI/CD
2. Необходимо установить ingress-certs для автоматического конфигурирования сертификатов Lets-Encrypt.
[Туториал](https://cloud.yandex.ru/docs/managed-kubernetes/tutorials/ingress-cert-manager)
    1. Установить чарты ingress-nginx
   ```
   helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
   helm repo update
   helm install ingress-nginx ingress-nginx/ingress-nginx --namespace ingress-cert --create-namespace
   ```
   1. Установить манифесты cert-manager
   ```shell
   kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/v1.9.1/cert-manager.yaml
   ```
#### Деплой приложения Momo Store
1. Перейти в папку kubernetes/momo-store
2. Заполнить values.yaml необходимыми данными
3. Выполнить установку helm чарта для staging или production
```shell
helm upgrade --install momo-store-$ENVIRONMENT_TYPE \
        --set global.environment=$ENVIRONMENT_TYPE \
        --set frontend.fqdn=${MOMO_STORE_URL} \
        --set secrets.dockerConfigJson=${DOCKER_CONFIG_JSON} \
        --set frontend.image.tag=${FRONTEND_DOCKER_TAG} \
        --set backend.image.tag=${BACKEND_DOCKER_TAG} \
        --set frontend.letsencryptEmail=${LETSENCRYPT_EMAIL} \
        --atomic --timeout 15m \
        --namespace momo-store-$ENVIRONMENT_TYPE \
        --create-namespace \
          nexus/momo-store
```
#### CI/CD Momo Store
Конвейер CI/CD содержит архивирование и версионирование helm чарта, а также деплой на инфраструктуру staging
и в ручном режиме на production, если пушиться в дефолтную ветку (main).

В манифестах настроены affinity таким образом,
чтобы поды были развернуты на той ноде, к которой привязан лейбл staging/production.

Репозиторий helm чарта в [nexus](https://nexus.praktikum-services.ru/repository/momo-store-alekseev-helm/)
#### Деплой и конфигурирования сервиса мониторинга приложения Momo Store
1. Перейти в папку kubernetes/monitoring-tools
2. Заполнить values.yaml необходимыми данными
3. Выполнить установку helm чарта
```shell
helm upgrade --install momo-monitoring \
        --set frontend.letsencryptEmail=${LETSENCRYPT_EMAIL} \
        --atomic --timeout 15m \
        --namespace infra \
        --create-namespace ./
```
#### Конфигурация сервиса мониторинга приложения Momo Store
1. В интерфейсе [grafana](https://momo-store-grafana.virtulab-services.ml/) настроены data sources для loki и prometheus.
В [дашборде](https://momo-store-grafana.virtulab-services.ml/d/TqVopPS4k/momo-store?orgId=1) выведены метрики приложения и логи.
Можно переключаться между production и staging сегментом. Логин пароль admin/admin
2. В [интерфейсе](https://momo-store-prometheus.virtulab-services.ml/graph?g0.expr=&g0.tab=1&g0.stacked=0&g0.show_exemplars=0&g0.range_input=1h) prometheus можно посмотреть таргеты и поискать текущие метрики
