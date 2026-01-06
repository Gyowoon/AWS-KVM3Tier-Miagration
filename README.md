# Note 
- 각 디렉터리 내부 README.MD 참고

# uv 사용법 
- uv.lock 파일 기반으로 올바른 가상환경을 재구성 할 수 있습니다. 
```bash
git clone <현재 주소>
uv sync
```
# uv 불가 시
- pip + requirement.txt 를 통해 동일한 결과를 얻을 수 있습니다.
```bash
uv pip compile pyproject.toml -o requirements.txt
git clone <현재 주소>
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```
