# bet

각각 독립 배포되는 두 개의 저장소로 구성:

- **bet-api** — NestJS + TypeORM 백엔드. MySQL DB, 인증(JWT), 베팅/지갑
  로직, wisetoto 경기/전적 데이터 크롤러, 예측픽 봇, 이메일/S3를 담당.
- **bet-client** — Next.js (App Router) 프론트엔드. BFF 역할을 함: 
  `src/app/api/**/route.ts` 핸들러가 `lib/bet-api-client.ts`를 통해
  bet-api로 프록시하고, 세션을 httpOnly 쿠키로 보관 — 브라우저는 JWT를
  절대 직접 보지 않음.

각 프로젝트는 자체 README/CLAUDE.md/git 저장소를 가지고 있으니 프로젝트별
상세 내용은 그쪽을 참고할 것. 이 파일은 두 프로젝트에 걸친 내용만 다룸.

## 구조

```
bet-api/src/modules/    auth, member, wallet, betting, pick, contest, matches, admin, mail, storage
bet-client/src/app/     라우트(App Router) + api/ (BFF 프록시 라우트)
bet-client/src/lib/     bet-api-client.ts (프록시 fetch), auth-cookie.ts, validation/
```

## 로컬 실행

```bash
# bet-api
cd bet-api && pnpm install && cp .env.example .env   # 실제 값으로 채우기
pnpm run start:dev        # http://localhost:3001

# bet-client
cd bet-client && pnpm install && cp .env.example .env.local
pnpm dev                  # http://localhost:3000, BET_API_BASE_URL로 프록시
```

bet-api 테스트: `pnpm test` (유닛, DB 불필요) / `pnpm test:e2e` (docker-compose로
일회용 MySQL 컨테이너를 띄움, 공유 DB는 절대 사용하지 않음).

## 두 저장소 공통 규칙

- **인증 경계**: bet-client는 JWT를 클라이언트 쪽에 절대 저장하지 않음.
  인증이 필요한 모든 요청은 브라우저 → bet-client 라우트 핸들러(쿠키 읽음)
  → `Authorization: Bearer`로 bet-api 순서로 감. 예외: 채팅 웹소켓은
  브라우저에서 bet-api의 socket.io 게이트웨이로 직접 연결
  (`NEXT_PUBLIC_BET_API_WS_URL`이 이 때문에 존재), 원본 세션 토큰이 아닌
  단기 티켓으로 인증함.
- **TZ=Asia/Seoul은 필수 설정** — bet-api에서 betman 피드가 타임존 정보
  없는 KST 문자열을 주는데 이를 `new Date(...)`로 파싱하면 프로세스의
  로컬 TZ가 적용됨. TZ가 잘못되면 경기 시간이 9시간 어긋남.
- **`synchronize`는 항상 `false`** — bet-api의 TypeORM 설정 전반의 규칙.
  유일한 예외는 `test/sync-schema.ts`이며, 이는 e2e 테스트용 일회용
  컨테이너에만 적용됨.
