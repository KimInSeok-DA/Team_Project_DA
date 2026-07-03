# team-1 — OULAD EDA

Open University Learning Analytics Dataset(OULAD) 기반 탐색적 데이터 분석(EDA).

- 데이터 출처: [Kaggle — student-demographics-online-education-dataoulad](https://www.kaggle.com/datasets/anlgrbz/student-demographics-online-education-dataoulad)

## 프로젝트 구조

```
team-1/
├── data/                         # Kaggle 데이터 (git 제외, 아래 명령으로 다운로드)
├── notebooks/
│   ├── 01_student_demographics_eda.ipynb   # 인구통계 × 학습결과
│   └── 02_vle_engagement_eda.ipynb         # VLE 클릭로그(1,065만행) 참여도 분석
├── main.py
└── pyproject.toml
```

## 데이터셋 테이블

| 파일 | 설명 | 행 수 |
|------|------|------|
| `studentInfo.csv` | 학생 인구통계 + 최종 결과(`final_result`) | 32,593 |
| `studentRegistration.csv` | 등록/등록취소 시점 | 32,593 |
| `assessments.csv` | 평가 항목 정의 | 206 |
| `studentAssessment.csv` | 학생별 평가 제출/점수 | 173,912 |
| `courses.csv` | 과목(모듈)·학기 | 22 |
| `vle.csv` | 온라인 학습자원 메타데이터 | 6,364 |
| `studentVle.csv` | 학생별 VLE 클릭 로그 (≈450MB) | 10,655,280 |

## 세팅

```bash
# 1) 의존성 설치 (uv)
uv sync

# 2) 데이터 다운로드 (~/.kaggle/kaggle.json 필요)
uv run kaggle datasets download -d anlgrbz/student-demographics-online-education-dataoulad -p data --unzip

# 3) 노트북 실행
uv run jupyter lab
```

## 노트북 요약

**01 — 인구통계 × 학습결과**
성별·지역·학력·연령·IMD band(사회경제 지표)와 `final_result`(Pass/Fail/Withdrawn/Distinction)의
관계. 평가 점수·등록 시점 등 행동 신호도 결과와 강하게 연관.

**02 — VLE 참여도**
1,065만 행 클릭 로그를 학생 단위로 집계(총 클릭·활동 일수·자원 수). 참여도는 성공 그룹에서
뚜렷하게 높고, **초반 4주 참여도**만으로도 결과가 갈려 조기 경보 모델의 핵심 피처 후보.