# SQL Queries

#SQL DDL statements to create tables

CREATE TABLE cd.members
    (
       memid INT NOT NULL, 
       surname VARCHAR(200) NOT NULL, 
       firstname VARCHAR(200) NOT NULL, 
       address VARCHAR(300) NOT NULL, 
       zipcode INT NOT NULL, 
       telephone VARCHAR(20) NOT NULL, 
       recommendedby INT,
       joindate TIMESTAMP NOT NULL,
       CONSTRAINT members_pk PRIMARY KEY (memid),
       CONSTRAINT fk_members_recommendedby FOREIGN KEY (recommendedby)
            REFERENCES cd.members(memid) ON DELETE SET NULL
    );
    

CREATE TABLE cd.facilities
    (
       facid INT NOT NULL, 
       name VARCHAR(100) NOT NULL, 
       membercost numeric NOT NULL, 
       guestcost numeric NOT NULL, 
       initialoutlay numeric NOT NULL, 
       monthlymaintenance numeric NOT NULL, 
       CONSTRAINT facilities_pk PRIMARY KEY (facid)
    );

CREATE TABLE cd.bookings
    (
       bookid INT NOT NULL, 
       facid INT NOT NULL, 
       memid INT NOT NULL, 
       starttime TIMESTAMP NOT NULL,
       slots INT NOT NULL,
       CONSTRAINT bookings_pk PRIMARY KEY (bookid),
       CONSTRAINT fk_bookings_facid FOREIGN KEY (facid) REFERENCES cd.facilities(facid),
       CONSTRAINT fk_bookings_memid FOREIGN KEY (memid) REFERENCES cd.members(memid)
    );


## Insert some data into a table

INSERT INTO cd.facilities
VALUES (9, 'Spa', 20, 30, 100000, 800);          

## Insert calculated data into a table

INSERT INTO cd.facilities
    SELECT (SELECT MAX(facid) FROM cd.facilities)+1, 'Spa', 20, 30, 100000, 800;          

## Update some existing data

UPDATE cd.facilities
    SET initialoutlay = 10000
    WHERE facid = 1;  

## Update a row based on the contents of another row
 
UPDATE cd.facilities
    SET
        membercost = (SELECT membercost * 1.1 FROM cd.facilities WHERE facid = 0),
        guestcost = (SELECT guestcost * 1.1 FROM cd.facilities WHERE facid = 0)
    WHERE facid = 1;  

## Delete all bookings

DELETE FROM cd.bookings;  

## Delete a member from the cd.members table

DELETE FROM cd.members WHERE memid = 37;          

## Control which rows are retrieved

SELECT facid, name, membercost, monthlymaintenance 
	FROM cd.facilities 
	WHERE 
		membercost > 0 AND 
		membercost < (monthlymaintenance/50.0);          

## Basic string search

SELECT *
	FROM cd.facilities 
	WHERE name LIKE '%Tennis%'; 

## Matching against multiple possible values

SELECT *
	FROM cd.facilities 
	WHERE facid IN (1,5);  

## Working with dates

SELECT memid, surname, firstname, joindate 
	FROM cd.members
	WHERE joindate >= '2012-09-01';

## Combining results from multiple queries

SELECT surname FROM cd.members
UNION
SELECT name FROM cd.facilities;

 ## Retrieve the start times of members' bookings

SELECT bks.starttime 
	FROM
		cd.bookings bks
		INNER JOIN cd.members mems
		ON mems.memid = bks.memid
	WHERE mems.firstname='David' AND mems.surname='Farrell'; 

## Work out the start times of bookings for tennis courts

SELECT bks.starttime AS start, facs.name AS name
	FROM cd.facilities facs
		INNER JOIN cd.bookings bks
		ON facs.facid = bks.facid
	WHERE 
		facs.name IN ('Tennis Court 2','Tennis Court 1') AND
		bks.starttime >= '2012-09-21' AND bks.starttime < '2012-09-22'
ORDER BY bks.starttime;   

## Produce a list of all members, along with their recommender

SELECT mems.firstname as memfname, mems.surname as memsname, recs.firstname as recfname, recs.surname as recsname
	FROM cd.members mems
		LEFT OUTER JOIN cd.members recs
		ON recs.memid = mems.recommendedby
ORDER BY memsname, memfname;   

## Produce a list of all members who have recommended another member

 SELECT DISTINCT recs.firstname as firstname, recs.surname as surname
	FROM cd.members mems
		INNER JOIN cd.members recs
		ON recs.memid = mems.recommendedby
ORDER BY surname, firstname;

## Produce a list of all members, along with their recommender, using no joins.

SELECT DISTINCT mems.firstname || ' ' ||  mems.surname as member,
	(SELECT recs.firstname || ' ' || recs.surname as recommender 
		FROM cd.members recs 
		WHERE recs.memid = mems.recommendedby
	)
	FROM cd.members mems
ORDER BY member;  

## Count the number of recommendations each member makes.

SELECT recommendedby, COUNT(*) 
	FROM cd.members
	WHERE recommendedby IS NOT NULL
	GROUP BY recommendedby
ORDER BY recommendedby;

## List the total slots booked per facility

SELECT facid, sum(slots) AS "Total Slots"
	FROM cd.bookings
	GROUP BY facid
ORDER BY facid;   

## List the total slots booked per facility in a given month

SELECT facid, SUM(slots) AS "Total Slots"
	FROM cd.bookings
	WHERE starttime >= '2012-09-01' AND starttime < '2012-10-01'
	GROUP BY facid
ORDER BY SUM(slots);

## List the total slots booked per facility per month

SELECT facid, EXTRACT(month from starttime) AS month, SUM(slots) AS "Total Slots"
	FROM cd.bookings
	WHERE extract(year from starttime) = '2012'
	GROUP BY facid, month
ORDER BY month;   

 ## Find the count of members who have made at least one booking

SELECT COUNT(DISTINCT memid) FROM cd.bookings      

## List each member's first booking after September 1st 2012

SELECT mems.surname, mems.firstname, mems.memid, MIN(bks.starttime) as starttime
	FROM cd.bookings bks
	    INNER JOIN cd.members mems
	    ON mems.memid = bks.memid
	WHERE starttime >= '2012-09-01'
	GROUP BY mems.surname, mems.firstname, mems.memid
ORDER BY mems.memid;      

## Produce a list of member names, with each row containing the total member count

SELECT COUNT(*) OVER(), firstname, surname
	FROM cd.members
ORDER BY joindate    

## Produce a numbered list of members

SELECT row_number() OVER(ORDER BY joindate), firstname, surname
	FROM cd.members
ORDER BY joindate;

## Output the facility id that has the highest number of slots booked

SELECT facid, total FROM (
	SELECT facid, SUM(slots) total, rank() OVER (ORDER BY SUM(slots) DESC) rank
        FROM cd.bookings
		GROUP BY facid
	) AS ranked
	WHERE rank = 1          

## Format the names of members

SELECT surname || ', ' || firstname AS name FROM cd.members;

## Find telephone numbers with parentheses

SELECT memid, telephone FROM cd.members WHERE telephone ~ '[()]';

## Count the number of members whose surname starts with each letter of the alphabet

SELECT SUBSTR (mems.surname,1,1) as letter, COUNT(*) AS count 
    FROM cd.members mems
    GROUP BY letter
    ORDER BY letter  