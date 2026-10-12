# Tuuvo — Site Institucional

Repositório oficial do site institucional e landing page da plataforma Tuuvo.

## Domínios
- **Produção:** `https://tuuvo.com.br` e `https://tuuvo.app.br`
- **Redirecionamento:** `www.tuuvo.com.br` e `www.tuuvo.app.br`

## Arquitetura
- **Web Server:** Nginx Alpine servindo conteúdo estático e rota de saúde `/health`.
- **Proxy Reverso & SSL:** Caddy com certificados automáticos Let's Encrypt / ZeroSSL.
- **Porta Interna:** `3300` (Docker)

## Deploy Contínuo (CI/CD)
O deploy é realizado automaticamente via GitHub Actions em push na branch `main`:
1. Empacota a aplicação
2. Envia para a VPS (`/opt/tuuvo/site`)
3. Executa `./tuuvo.sh install` com validação de healthcheck e suporte a rollback (`./tuuvo.sh rollback`).
