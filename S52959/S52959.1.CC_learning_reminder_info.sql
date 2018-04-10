SET start_date='2018-04-01';
SET end_date='2018-04-07';

-- memo:学习提醒打开app（此处定义同lingome push打开app，一段时间内的打开都计入）/展示学习提醒比例
-- task：https://phab.llsapp.com/T52959
-- requester：Junjie Wang
-- author：Ivy.yang
-- labels: CC, learning reminder

--获取展示学习提醒的CC用户
WITH open_reminder_users AS(
SELECT a.data_date,a.user_id,b.learning_reminder,b.goal_created_at
     FROM llsdw.dw_lls_cc_valid_package_day  a
     JOIN (SELECT user_id,learning_reminder,goal_created_at
           FROM llsdw.dw_lls_cc_user_setting
           WHERE data_date=cast(date_add('day',-1,cast(CURRENT_DATE AS date)) AS varchar)) b 
     ON a.user_id = b.user_id
     WHERE a.data_date BETWEEN ${start_date} AND ${end_date} and learning_reminder=1
)

--计算当天展示学习提醒且打开APP的用户/展示学习提醒用户 
SELECT a.data_date, count(CASE WHEN b.mysql_id IS NOT NULL THEN a.user_id END) open_app_users  --打开APP用户数
      ,count(CASE WHEN to_date(goal_created_at) <= a.data_date AND learning_reminder = 1 THEN a.user_id END) open_reminder_users --展示学习提醒用户数
      ,round(1.0*count(CASE WHEN b.mysql_id IS NOT NULL THEN a.user_id END)/count(CASE WHEN to_date(goal_created_at) <= a.data_date AND learning_reminder = 1 THEN a.user_id END),2) reminder_open_app_rate
FROM open_reminder_users a  
LEFT JOIN (SELECT data_date,mysql_id
          FROM production_etl.active_login_users_black_list
          WHERE data_date BETWEEN ${start_date} AND ${end_date}
          AND app_name = 'lls_cn_prod'
          AND lls_compare_app_version(app_version,'6.0')>=0) b 
ON a.data_date = b.data_date  AND a.user_id = b.mysql_id
GROUP BY a.data_date
ORDER BY a.data_date