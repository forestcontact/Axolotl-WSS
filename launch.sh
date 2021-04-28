#! /bin/sh
set -xu

export PATH=/app:$PATH

echo $CERT_DOT_PEM | base64 -d > cert.pem

cloudflared tunnel --origincert cert.pem cleanup $USER || true
cloudflared tunnel --origincert cert.pem delete -f $USER || true
TUNNEL=$(cloudflared tunnel --origincert cert.pem create $USER | tail -n 1 | sed -e 's/ /\n/g' | tail -n 1)
cloudflared tunnel --origincert cert.pem route dns $USER $USER.infragora.org || true
cloudflared tunnel --origincert cert.pem --hostname $USER.infragora.org run $USER &

TUNNEL=$(cloudflared tunnel --origincert cert.pem list | grep $USER | tail -n 1 | awk '{print $1}')

EXISTING=$(curl -X GET "https://api.cloudflare.com/client/v4/zones/0b7d00d1182637b622d4f8658b28aba0/dns_records?type=CNAME&name=$USER.infragora.org" \
	-H "Authorization: Bearer $CF_API_KEY" \
	-H "Content-Type:application/json" | jq -r .result[].id)

curl -X PATCH "https://api.cloudflare.com/client/v4/zones/0b7d00d1182637b622d4f8658b28aba0/dns_records/$EXISTING" \
	-H "Authorization: Bearer $CF_API_KEY" \
	-H "Content-Type:application/json" --data '{"content":"'$TUNNEL.cfargotunnel.com'"}'

curl "https://kocyorfobgaebgipwexo.supabase.co/rest/v1/users?select=account&id=eq.$USER" \
	-H "apikey: $SUPABASE_API_KEY" \
	-H "Authorization: Bearer $SUPABASE_API_KEY" | jq -cM .[].account > data/+$USER

websocat --oneshot --text --ping-interval=1 --ping-timeout=2 --exec-sighup-on-stdin-close --restrict-uri /ws --set-environment --exit-on-eof ws-listen:127.0.0.1:8080 cmd:'/app/link.sh '

curl -X PATCH "https://kocyorfobgaebgipwexo.supabase.co/rest/v1/users?id=eq.$USER" \
	-H "apikey: $SUPABASE_API_KEY" \
	-H "Authorization: Bearer $SUPABASE_API_KEY" \
	-H "Content-Type: application/json" \
	-H "Prefer: return=representation" --data-binary '{"account":'$(cat /app/data/+$USER | sed -e 's/\\u0000//g' | jq -c)'}' | wc # hat-tip Dillon
