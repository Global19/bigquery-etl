CREATE OR REPLACE FUNCTION udf_js.weighted_quantile(
  percentile FLOAT64,
  histogram ARRAY<STRUCT<key STRING, value FLOAT64>>,
  type STRING
)
RETURNS FLOAT64
LANGUAGE js
AS
  '''
  if (percentile < 0 || percentile > 100) {
      throw "percentile must be a value between 0 and 100";
  }

  let keys = histogram.map(bucket => parseInt(bucket.key));
  let values = histogram.map(bucket => bucket.value);

  return weightedQuantile([percentile/100], keys, values)[0];
'''
OPTIONS
  (library = "gs://moz-fx-data-circleci-tests-bigquery-etl/wtdstats.js");

SELECT
  assert_equals(
    2.0,
    udf_js.weighted_quantile(
      50.0,
      ARRAY<STRUCT<key STRING, value FLOAT64>>[("0", 1), ("2", 1), ("3", 1)],
      "timing_distribution"
    )
  ),
  assert_equals(
    2.5,
    udf_js.weighted_quantile(
      50.0,
      ARRAY<STRUCT<key STRING, value FLOAT64>>[("0", 1), ("2", 2), ("3", 1)],
      "timing_distribution"
    )
  );

#xfail
SELECT
  udf_js.glean_percentile(
    101.0,
    ARRAY<STRUCT<key STRING, value FLOAT64>>[("0", 1), ("2", 2), ("3", 1)],
    "timing_distribution"
  );