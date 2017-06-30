-- JSON output for BrAPI calls:

-- - /brapi/v1/trials
--   https://github.com/plantbreeding/API/blob/master/Specification/Trials/ListTrialSummaries.md

SELECT json_agg(json_build_object(
  'trialDbId', t.trialDbId,
  'trialName', t.name,
  'startDate', t.startDate,
  'endDate', t.endDate,
  'active', t.active,

  'programDbId', p.programDbId,
  'programName', p.name,

  'studies', array(
    SELECT json_build_object(
      'studyDbId', s.studyDbId,
      'studyName', s.name,
      'locationName', l.name
    )
    FROM study s
    LEFT JOIN location l
      ON l.locationDbId = s.locationDbId
    WHERE s.trialDbId = t.trialDbId
  ),

  -- Aggregate trial_additional_info for the current trial into a single json object
  'additionalInfo', (
    SELECT json_object_agg(key, value)
    FROM (
        SELECT
          tai.key AS key, -- info key
          CASE WHEN count(tai.value) = 1
            THEN to_json(string_agg(tai.value, '')) -- value as simple text
            ELSE json_agg(tai.value) -- value as array of text
          END AS value
        FROM trial_additional_info tai
        WHERE tai.trialDbId = t.trialDbId
        GROUP BY key
    ) ai
  )
))
FROM trial t
LEFT JOIN program p
  ON p.programDbId = t.programDbId
