# 크레마 지수 — 집 PC 자동화 가이드


전제: 집 PC에 이 폴더(`크레마 지수`)가 그대로 있고, 집에서는 **개인 Claude 계정**을 사용.


목표: 핸드폰에서 최신 크레마 지수를 보고, 데이터 갱신은 자동으로.


두 가지 방법 중 하나를 선택하면 됩니다.


---


## 방법 A — Claude Code 예약 작업 (가장 간단)


집 PC가 아침에 켜져 있는 편이라면 이 방법이 제일 쉽습니다.


1. 집 PC에서 Claude Code(데스크톱 앱)를 열고 이 폴더를 프로젝트로 연다.


2. Claude에게 한 번만 요청:


   > "이 폴더의 index.html을 메인 페이지로, history.html·data.js·history-data.js를 함께 아티팩트로 게시해줘"


   - 개인 계정의 **비공개 링크**가 생긴다. 핸드폰에서 개인 계정으로 claude.ai에 로그인하면 열 수 있다.


3. 자동화 요청:


   > "매일 아침 7시 30분에 update-data.ps1을 실행하고, 생성된 data.js와 history-data.js를 방금 그 아티팩트 URL로 재게시하는 예약 작업을 만들어줘"


- 장점: 추가 계정 불필요, 링크가 비공개(본인만 접근).


- 제약: 갱신 시점에 집 PC가 켜져 있고 Claude 앱이 실행 중이어야 한다.


  (폰에서 보는 것 자체는 언제나 가능 — 마지막으로 게시된 데이터가 보임)


---


## 방법 B — GitHub Pages + Actions (PC가 꺼져 있어도 자동, 추천)


클라우드(GitHub)가 매일 알아서 데이터를 받아 갱신하므로 집 PC가 꺼져 있어도 된다.


준비물: 개인 GitHub 계정 (github.com, 무료).


1. **저장소 만들기**: github.com → New repository → 이름 예: `crema-index` → **Public** 선택 → Create.


   - 무료 계정은 Public 저장소만 GitHub Pages를 쓸 수 있다. 이 폴더엔 공개 시장 데이터뿐이라 민감정보는 없지만, URL을 아는 사람은 누구나 볼 수 있다는 점은 감안할 것.


2. **파일 업로드**: 이 폴더의 내용 전체를 저장소에 올린다.


   - 웹에서: 저장소 페이지 → "uploading an existing file" → 파일 드래그&드롭.


     필수 파일: `index.html`, `history.html`, `update-data.ps1`, `data.js`, `history-data.js`,


     그리고 `.github/workflows/update-data.yml` (자동화의 핵심 — 이미 이 폴더에 준비돼 있음).


     ※ 웹 업로드는 폴더 구조(.github/workflows/)를 유지해서 올려야 한다. 드래그&드롭 시 폴더째 끌어오면 된다.


   - git에 익숙하면: `git init` → `git add .` → `git commit` → `git push`.


3. **Actions 쓰기 권한**: 저장소 Settings → Actions → General → Workflow permissions →


   **"Read and write permissions"** 선택 후 Save. (Actions가 갱신된 데이터를 커밋하는 데 필요)


4. **Pages 켜기**: Settings → Pages → Source: **Deploy from a branch** → Branch: `main` / `(root)` → Save.


5. **테스트**: Actions 탭 → "Update Crema data" → **Run workflow**로 1회 수동 실행.


   초록 체크가 뜨면 몇 분 뒤 `https://<깃허브아이디>.github.io/crema-index/` 에서 페이지 확인.


이후에는 **매 거래일 한국시간 아침 7:30**에 자동으로 데이터가 갱신된다.


핸드폰 홈 화면에 위 URL을 바로가기로 추가하면 앱처럼 쓸 수 있다 (로그인 불필요).


- 참고: GitHub는 저장소에 60일간 커밋 활동이 없으면 예약 실행을 멈추는데,


  이 워크플로는 매일 데이터를 커밋하므로 해당되지 않는다.


---


## 공통 참고


- `크레마지수 업데이트.bat` 는 집 PC에서도 그대로 동작한다 (로컬에서 수동 원클릭 갱신 + 브라우저 열기).


- 방법 B를 쓰더라도 로컬 bat와 충돌하지 않는다 — 로컬 파일과 GitHub의 파일은 별개.


- 회사 PC에서는 외부 업로드가 불가하므로 이 가이드의 작업은 모두 집 PC에서 할 것.


- 집 사본이 최신인지 확인: 폴더에 `history.html`이 있으면 2026-09 이후 버전이다.


  없다면 index.html 등 본체 파일도 다시 가져와야 한다.


---


## 부록 — 이 가이드 파일만 가져온 경우 (방법 B에 필요한 2가지)


집 폴더에는 아래 두 가지가 없거나 구버전이다. 집 PC의 Claude Code에 이 섹션을 보여주며


"부록대로 두 파일을 만들어/고쳐줘"라고 하면 된다 (직접 만들어도 됨).


### 1) 새 파일: `.github/workflows/update-data.yml`


폴더 안에 `.github\workflows\` 하위 폴더를 만들고 아래 내용 그대로 저장:


```yaml


name: Update Crema data


on:


  schedule:


    # UTC 22:30 = 한국시간 07:30 (미국 장 마감 후, 화~토 아침)


    - cron: '30 22 * * 1-5'


  workflow_dispatch: {}


jobs:


  update:


    runs-on: ubuntu-latest


    permissions:


      contents: write


    steps:


      - uses: actions/checkout@v4


      - name: Fetch market data


        shell: pwsh


        run: ./update-data.ps1


      - name: Commit updated data


        run: |


          git config user.name "github-actions[bot]"


          git config user.email "github-actions[bot]@users.noreply.github.com"


          git add data.js history-data.js


          git diff --cached --quiet || git commit -m "chore: update market data"


          git push


```


### 2) 수정: `update-data.ps1` 맨 끝부분


클라우드(GitHub Actions)에서 실행될 때 키 입력을 기다리다 멈추지 않도록,


파일 맨 끝의 `if ($failed.Count -gt 0) { ... }` 블록을 아래로 교체:


```powershell


if ($failed.Count -gt 0) {


    Write-Host "Some sources failed: $($failed -join ', ')" -ForegroundColor Yellow


    if (-not $env:CI) {


        # Interactive run (double-clicked bat): keep the window open so the user sees the warning


        Write-Host "Press any key to continue..."


        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")


    } else {


        exit 1


    }


}


```


