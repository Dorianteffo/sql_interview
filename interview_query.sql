---Calculate the average rating given by students to each teacher for each session created. 
---Also, provide the batch name for which session was conducted.

WITH avg_session AS (
		SELECT session_id, ROUND(CAST(AVG(rating) AS DECIMAL),2) AS avg_rating
		FROM attendances
		GROUP BY session_id
		)
SELECT s.id AS session_id ,u.name AS Teacher_name ,b.name AS batch_name ,avg_session.avg_rating
FROM sessions s
JOIN batches b ON s.batch_id = b.id
JOIN avg_session ON s.id = avg_session.session_id
JOIN users u ON s.conducted_by = u.id;




---Find the attendance percentage  for each session for each batch.
---Also mention the batch name and users name who has conduct that session

WITH supposed_total AS (
		SELECT batch_id, COUNT(user_id) AS total_sup
		FROM student_batch_maps 
		WHERE active = True
		GROUP BY batch_id
		ORDER BY batch_id
		), 
	real_total AS (
		SELECT a.session_id AS session_id,s.batch_id AS batch_id, COUNT(a.student_id) AS total_real
		FROM attendances a
		JOIN sessions s ON a.session_id = s.id
		JOIN users u ON a.student_id = u.id
		WHERE u.active = True
		GROUP BY a.session_id, s.batch_id
		ORDER BY a.session_id
		),
	batch_name AS (
		SELECT id,name 
		FROM batches), 
	instructor_name AS (
		SELECT id,name
		FROM users)
SELECT s.id AS session_id,bn.name AS batch_name,inst.name AS instructor_name,
ROUND(((rt.total_real::DECIMAL)/(st.total_sup::DECIMAL))*100,2) AS attendance_percentage
FROM sessions s
JOIN supposed_total st
ON st.batch_id = s.batch_id
JOIN real_total rt
ON s.id = rt.session_id AND s.batch_id = rt.batch_id
JOIN batch_name bn 
ON s.batch_id = bn.id
JOIN instructor_name inst
ON s.conducted_by = inst.id;



--- What is the average percentage of marks scored by each student in all the tests the student had appeared?
WITH students_score AS ( 
		SELECT user_id,score,t.total_mark,
		ROUND((score::DECIMAL/t.total_mark::DECIMAL)*100,2) AS percentage, 
		COUNT(*) OVER(PARTITION BY user_id) AS total_tests
		FROM test_scores ts 
		JOIN tests t ON ts.test_id = t.id 
		GROUP BY user_id,score,t.total_mark
		ORDER BY user_id
	)
SELECT u.id ,u.name, ss.total_tests AS number_of_tests,
ROUND(SUM(ss.percentage)/ss.total_tests,2)  AS avg_percentage
FROM users u
JOIN students_score ss
ON u.id = ss.user_id
GROUP BY u.id,ss.total_tests
ORDER BY u.id;



---A student is passed when he scores 40 percent of total marks in a test. 
---Find out how many students passed in each test. Also mention the batch name for that test.

SELECT test_id,b.name AS batch_name,
COUNT(CASE WHEN ts.score>=t.total_mark*40/100 THEN ts.user_id END) AS success_student
FROM test_scores ts
JOIN tests t ON ts.test_id = t.id
JOIN batches b ON t.batch_id = b.id
GROUP BY test_id, b.name
ORDER BY test_id;



---Find out how many percentage of students have passed in each test

WITH student_total AS ( 
		SELECT test_id, COUNT(*) AS total_participant
		FROM test_scores
		GROUP BY test_id
			)
SELECT ts.test_id,b.name AS batch_name,
COUNT(CASE WHEN ts.score>=t.total_mark*40/100 THEN ts.user_id END) AS success_student, 
ROUND((COUNT(CASE WHEN ts.score>=t.total_mark*40/100 THEN ts.user_id END)::DECIMAL/st.total_participant::DECIMAL)*100,2) AS percentage_succeed
FROM test_scores ts
JOIN tests t ON ts.test_id = t.id
JOIN batches b ON t.batch_id = b.id
JOIN student_total st ON ts.test_id = st.test_id
GROUP BY ts.test_id, b.name,st.total_participant
ORDER BY test_id;

