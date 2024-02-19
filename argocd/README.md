# Argo CD 공식 홈페이지
https://argo-cd.readthedocs.io/en/stable/getting_started/

# Argo CD Install Yaml
## 전체 설치
https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

## UI, SSO, 다중클러스터 기능 제외 / 핵심 기능 설치
https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/core-install.yaml

# Install 참고 URL
# "추천"
https://findstar.pe.kr/2023/06/04/argocd-installation/
https://kh-guard.tistory.com/31

--------------------------------------------
# 1. Install
# "전체"
kubectl create namespace argocd

kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# "특정 기능 제외"
kubectl create namespace argocd

kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/core-install.yaml

# 2. CLI Download
brew install argocd

# 3. API 서버 액세스
"서비스 유형 로드 밸런서"
kubectl patch svc argocd-server -n argocd -p '{"spec":{"type":"LoadBalancer"}}'

# "포트 포워딩"
'kubectl port-forward svc/argocd-server -n argocd 8080:443'
