SELECT A.RNR,
       A.NUM_ROWS,
       B.START_LOAD,
       B.END_LOAD
FROM
  (SELECT RNR,
          sum(REQ_SELECT) NUM_ROWS
   FROM sapsr3.RSMONFACT
   WHERE RNR in
       (SELECT DISTINCT RNR
        FROM sapsr3.RSMONICTAB
        WHERE INFOCUBE in ('X_CUBE' /* Target */ )
          AND to_date(substr(to_char(TIMESTAMP), 1, 8), 'yyyymmdd') BETWEEN (sysdate - 3) AND (sysdate + 1)/* Time period shifted 1 day past and future */ )
   GROUP BY RNR) A
INNER JOIN
  (SELECT RNR,
          (to_date(min(TIMESTAMP), 'YYYYMMDDHH24MISS') + 0.25) START_LOAD,
          (to_date(max(TIMESTAMP), 'YYYYMMDDHH24MISS') + 0.25) END_LOAD
   FROM sapsr3.RSMONMESS
   WHERE RNR in
       (SELECT DISTINCT RNR
        FROM sapsr3.RSMONICTAB
        WHERE INFOCUBE in ('X_CUBE' /* Target */ )
          AND to_date(substr(to_char(TIMESTAMP), 1, 8), 'yyyymmdd') BETWEEN (sysdate - 3) AND (sysdate + 1)/* Time period shifted 1 day past and future */ )
   GROUP BY RNR) B ON A.RNR = B.RNR
WHERE B.START_DATE BETWEEN (sysdate - 2) AND sysdate /* Time period */
