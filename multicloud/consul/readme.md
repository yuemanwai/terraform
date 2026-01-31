# consul

## 使用port forward consul ui, 只限本機可見
kubectl port-forward svc/consul-ui 8500:8500 -n default
kubectl config current-context
kubectl config use-context <context-name>
