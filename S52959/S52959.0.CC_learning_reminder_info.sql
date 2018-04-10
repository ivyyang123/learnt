SET start_date='2018-04-01';
SET end_date='2018-04-07';

-- memo：CC用户学习提醒开关打开比例
-- task：https://phab.llsapp.com/T52959
-- requester：Junjie Wang
-- author：Ivy.yang
-- labels：CC,learning reminder

--获取可学且进入APP的CC用户
WITH cc_valid_act_user AS(
SELECT a.data_date,a.user_id
FROM llsdw.dw_lls_cc_valid_package_day  a
JOIN production_etl.active_login_users_black_list b
ON a.data_date = b.data_date  AND a.user_id = b.mysql_id
WHERE a.data_date BETWEEN ${start_date} AND ${end_date}
      AND b.data_date BETWEEN ${start_date} AND ${end_date}
      AND b.app_name = 'lls_cn_prod'
      AND lls_compare_app_version(app_version,'6.0')>=0
)


--计算CC用户中学习提醒开关打开的比例
SELECT a.data_date
       ,count(CASE WHEN to_date(goal_created_at) <= a.data_date AND learning_reminder = 1 THEN a.user_id END)  open_reminder_users --展示学习提醒用户数
       ,count(a.user_id) CC_users --在学CC用户数
       ,round(1.0*count(CASE WHEN to_date(goal_created_at) <= a.data_date AND learning_reminder = 1 THEN a.user_id END)/count(a.user_id),2) open_rate
FROM cc_valid_act_user a
LEFT JOIN
(SELECT user_id,learning_reminder,goal_created_at
FROM llsdw.dw_lls_cc_user_setting
WHERE data_date=cast(date_add('day',-1,cast(CURRENT_DATE AS date)) AS varchar)) b
ON a.user_id = b.user_id
GROUP BY a.data_date
ORDER BY a.data_date
;
