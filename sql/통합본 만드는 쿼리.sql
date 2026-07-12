-- 28일 이내 이탈 방지 분석용 통합 뷰
-- 그레인: (id_student, code_module, code_presentation) 1행
-- 원칙: "초반 28일 안에 확보 가능한 신호"만 피처로 사용 (그 이후 정보는 예측 시점엔 알 수 없으므로 제외)

CREATE OR REPLACE VIEW v_student_early_signal AS
WITH base AS (
    SELECT
        si.id_student,
        si.code_module,
        si.code_presentation,
        si.gender,
        si.region,
        si.highest_education,
        si.imd_band,
        si.age_band,
        si.num_of_prev_attempts,
        NULLIF(si.studied_credits, '')::integer AS studied_credits,
        si.disability,
        si.final_result,
        (si.final_result = 'Withdrawn')                                    AS label_churn,        -- 최종 이탈 여부(전체 기간)
        (NULLIF(sr.date_unregistration, '')::integer IS NOT NULL
         AND NULLIF(sr.date_unregistration, '')::integer BETWEEN 0 AND 28) AS label_churn_28d,     -- 28일 이내 이탈 여부(핵심 타겟)
        sr.date_registration,
        NULLIF(sr.date_unregistration, '')::integer                        AS date_unregistration,
        c.module_presentation_length
    FROM studentinfo si
    JOIN studentregistration sr
      ON sr.id_student = si.id_student
     AND sr.code_module = si.code_module
     AND sr.code_presentation = si.code_presentation
    JOIN courses c
      ON c.code_module = si.code_module
     AND c.code_presentation = si.code_presentation
),
assess_28 AS (
    -- 마감일(assessments.date)이 28일 이내인 평가 중, 28일 이내에 제출된 것만 집계
    SELECT
        sa.id_student,
        a.code_module,
        a.code_presentation,
        COUNT(*)                                            AS n_assessment_submitted_28,
        AVG(NULLIF(sa.score, '')::numeric)                  AS avg_score_28,
        AVG(sa.date_submitted - NULLIF(a.date,'')::integer)  AS avg_submit_delay_28
    FROM studentassessment sa
    JOIN assessments a ON a.id_assessment = sa.id_assessment
    WHERE NULLIF(a.date, '')::integer <= 28
      AND sa.date_submitted <= 28
    GROUP BY sa.id_student, a.code_module, a.code_presentation
),
vle_28 AS (
    -- 0~28일 사이의 VLE 클릭 로그만 집계
    SELECT
        sv.id_student,
        sv.code_module,
        sv.code_presentation,
        SUM(sv.sum_click)              AS total_click_28,
        COUNT(DISTINCT sv.date)        AS active_days_28,
        COUNT(DISTINCT sv.id_site)     AS distinct_resources_28
    FROM studentvle sv
    WHERE NULLIF(sv.date, '')::integer BETWEEN 0 AND 28
    GROUP BY sv.id_student, sv.code_module, sv.code_presentation
)
SELECT
    b.*,
    COALESCE(a28.n_assessment_submitted_28, 0) AS n_assessment_submitted_28,
    a28.avg_score_28,
    a28.avg_submit_delay_28,
    COALESCE(v28.total_click_28, 0)            AS total_click_28,
    COALESCE(v28.active_days_28, 0)            AS active_days_28,
    COALESCE(v28.distinct_resources_28, 0)     AS distinct_resources_28
FROM base b
LEFT JOIN assess_28 a28
  ON a28.id_student = b.id_student
 AND a28.code_module = b.code_module
 AND a28.code_presentation = b.code_presentation
LEFT JOIN vle_28 v28
  ON v28.id_student = b.id_student
 AND v28.code_module = b.code_module
 AND v28.code_presentation = b.code_presentation;

-- studentvle가 1,065만 행이라 GROUP BY/필터가 느릴 수 있음 -> 아래 인덱스로 개선
CREATE INDEX IF NOT EXISTS idx_studentvle_date ON studentvle (date);
CREATE INDEX IF NOT EXISTS idx_studentassessment_date_submitted ON studentassessment (date_submitted);

-- 사용 예 (Python으로 내보낼 때)
-- SELECT * FROM v_student_early_signal;

-- 28일이 아니라 다른 기준일(예: 14일, 21일)로 보고 싶으면
-- 이 파일 안의 "28" 을 원하는 숫자로 전부 바꿔서 재실행하면 됨.
