--1 
--dodanie indeksu dla tabeli transaction_category kolumna transaction_year indeksujemy po roku
EXPLAIN ANALYZE
select * from expense_tracker.transactions t inner join expense_tracker.transaction_category tc on (t.id_trans_cat=tc.id_trans_cat)
 where tc.category_name ='JEDZENIE' and (extract (year from transaction_date))='2016';

 --Nested Loop  (cost=0.00..291.57 rows=3 width=716) (actual time=0.346..4.466 rows=660 loops=1)
  --Join Filter: (t.id_trans_cat = tc.id_trans_cat)
  --Rows Removed by Join Filter: 891
  --->  Seq Scan on transaction_category tc  (cost=0.00..1.14 rows=1 width=662) (actual time=0.028..0.033 rows=1 loops=1)
    --    Filter: ((category_name)::text = 'JEDZENIE'::text)
      --  Rows Removed by Filter: 10
  --->  Seq Scan on transactions t  (cost=0.00..289.99 rows=36 width=54) (actual time=0.313..3.993 rows=1551 loops=1)
    --    Filter: (date_part('year'::text, (transaction_date)::timestamp without time zone) = '2016'::double precision)
      --  Rows Removed by Filter: 5591
--Planning Time: 0.746 ms
--Execution Time: 4.534 ms

CREATE INDEX trnsac_year_ind ON expense_tracker.transactions (extract(year from transaction_date));
EXPLAIN ANALYZE
select * from expense_tracker.transactions t inner join expense_tracker.transaction_category tc on (t.id_trans_cat=tc.id_trans_cat)
 where tc.category_name ='JEDZENIE' and (extract (year from transaction_date))='2016';

 --Nested Loop  (cost=4.56..94.50 rows=3 width=716) (actual time=0.303..1.158 rows=660 loops=1)
  --Join Filter: (t.id_trans_cat = tc.id_trans_cat)
  --Rows Removed by Join Filter: 891
  --->  Seq Scan on transaction_category tc  (cost=0.00..1.14 rows=1 width=662) (actual time=0.019..0.024 rows=1 loops=1)
    --    Filter: ((category_name)::text = 'JEDZENIE'::text)
      --  Rows Removed by Filter: 10
  --->  Bitmap Heap Scan on transactions t  (cost=4.56..92.92 rows=36 width=54) (actual time=0.270..0.553 rows=1551 loops=1)
    --    Recheck Cond: (date_part('year'::text, (transaction_date)::timestamp without time zone) = '2016'::double precision)
      --  Heap Blocks: exact=20
       -- ->  Bitmap Index Scan on trnsac_year_ind  (cost=0.00..4.55 rows=36 width=0) (actual time=0.253..0.253 rows=1551 loops=1)
         --     Index Cond: (date_part('year'::text, (transaction_date)::timestamp without time zone) = '2016'::double precision)
--Planning Time: 1.321 ms
--Execution Time: 1.267 ms
 

 --2
 --utworzenie widokÃƒÂ³w zmaterializowanych dla transakcji poszczegÃƒÂ³lnych wÃ…â€šaÃ…â€ºcicieli w danym roku- dla lat 
 --zakoÃ…â€žczonych.
 
 discard all;
explain analyze select 
            tc.category_name, ts.subcategory_name, tt.transaction_type_name, t.transaction_date,
            extract (year from t.transaction_date) trans_year, t.transaction_value, bat.ba_type
            from expense_tracker.transactions t 
                inner join expense_tracker.transaction_type tt on (t.id_trans_type =tt.id_trans_type) and extract(year from t.transaction_date)=2015
                inner join expense_tracker.transaction_subcategory ts on (t.id_trans_subcat= ts.id_trans_subcat)
                inner join expense_tracker.transaction_category tc on (t.id_trans_cat=tc.id_trans_cat)
                inner join expense_tracker.transaction_bank_accounts tba on (t.id_trans_ba =tba.id_trans_ba)
                inner join expense_tracker.bank_account_types bat on (tba.id_ba_typ=bat.id_ba_type)
                inner join expense_tracker.bank_account_owner bao on (bat.id_ba_own=bao.id_ba_own)and bao.owner_name = 'Janusz Kowalski';
 
        --Nested Loop  (cost=11.31..102.33 rows=12 width=490) (actual time=0.514..2.408 rows=256 loops=1)
  --Join Filter: (tba.id_trans_ba = t.id_trans_ba)
  --Rows Removed by Join Filter: 1074
 -- ->  Hash Join  (cost=9.14..97.90 rows=36 width=368) (actual time=0.351..1.558 rows=665 loops=1)
   --     Hash Cond: (t.id_trans_cat = tc.id_trans_cat)
     --   ->  Hash Join  (cost=7.89..96.52 rows=36 width=254) (actual time=0.278..1.208 rows=665 loops=1)
       --       Hash Cond: (t.id_trans_subcat = ts.id_trans_subcat)
         --     ->  Hash Join  (cost=5.67..94.20 rows=36 width=140) (actual time=0.186..0.823 rows=705 loops=1)
           --         Hash Cond: (t.id_trans_type = tt.id_trans_type)
             --       ->  Bitmap Heap Scan on transactions t  (cost=4.56..92.92 rows=36 width=26) (actual time=0.118..0.275 rows=705 loops=1)
               --           Recheck Cond: (date_part('year'::text, (transaction_date)::timestamp without time zone) = '2015'::double precision)
                 --         Heap Blocks: exact=11
                   --       ->  Bitmap Index Scan on trnsac_year_ind  (cost=0.00..4.55 rows=36 width=0) (actual time=0.101..0.101 rows=705 loops=1)
                     --           Index Cond: (date_part('year'::text, (transaction_date)::timestamp without time zone) = '2015'::double precision)
                   -- ->  Hash  (cost=1.05..1.05 rows=5 width=122) (actual time=0.042..0.043 rows=5 loops=1)
                     --     Buckets: 1024  Batches: 1  Memory Usage: 9kB
                       --   ->  Seq Scan on transaction_type tt  (cost=0.00..1.05 rows=5 width=122) (actual time=0.024..0.026 rows=5 loops=1)
             -- ->  Hash  (cost=1.54..1.54 rows=54 width=122) (actual time=0.077..0.078 rows=55 loops=1)
               --     Buckets: 1024  Batches: 1  Memory Usage: 11kB
                 --   ->  Seq Scan on transaction_subcategory ts  (cost=0.00..1.54 rows=54 width=122) (actual time=0.025..0.040 rows=55 loops=1)
       -- ->  Hash  (cost=1.11..1.11 rows=11 width=122) (actual time=0.058..0.059 rows=11 loops=1)
         --     Buckets: 1024  Batches: 1  Memory Usage: 9kB
           --   ->  Seq Scan on transaction_category tc  (cost=0.00..1.11 rows=11 width=122) (actual time=0.030..0.034 rows=11 loops=1)
 -- ->  Materialize  (cost=2.17..3.30 rows=2 width=122) (actual time=0.000..0.001 rows=2 loops=665)
   --     ->  Hash Join  (cost=2.17..3.29 rows=2 width=122) (actual time=0.148..0.154 rows=2 loops=1)
     --         Hash Cond: (tba.id_ba_typ = bat.id_ba_type)
       --       ->  Seq Scan on transaction_bank_accounts tba  (cost=0.00..1.07 rows=7 width=8) (actual time=0.024..0.026 rows=7 loops=1)
         --     ->  Hash  (cost=2.15..2.15 rows=2 width=122) (actual time=0.102..0.103 rows=2 loops=1)
           --         Buckets: 1024  Batches: 1  Memory Usage: 9kB
             --       ->  Hash Join  (cost=1.05..2.15 rows=2 width=122) (actual time=0.083..0.090 rows=2 loops=1)
               --           Hash Cond: (bat.id_ba_own = bao.id_ba_own)
                 --         ->  Seq Scan on bank_account_types bat  (cost=0.00..1.07 rows=7 width=126) (actual time=0.017..0.018 rows=7 loops=1)
                   --       ->  Hash  (cost=1.04..1.04 rows=1 width=4) (actual time=0.041..0.041 rows=1 loops=1)
                     --           Buckets: 1024  Batches: 1  Memory Usage: 9kB
                       --         ->  Seq Scan on bank_account_owner bao  (cost=0.00..1.04 rows=1 width=4) (actual time=0.024..0.026 rows=1 loops=1)
                         --             Filter: ((owner_name)::text = 'Janusz Kowalski'::text)
                           --           Rows Removed by Filter: 2
--Planning Time: 2.832 ms
--Execution Time: 2.780 ms    
            
 
 create materialized view expense_tracker.Janusz_trasactions_2015_year
    as
       select 
            tc.category_name, ts.subcategory_name, tt.transaction_type_name, t.transaction_date,
            extract (year from t.transaction_date) trans_year, t.transaction_value, bat.ba_type
            from expense_tracker.transactions t 
                inner join expense_tracker.transaction_type tt on (t.id_trans_type =tt.id_trans_type) and extract(year from t.transaction_date)=2015
                inner join expense_tracker.transaction_subcategory ts on (t.id_trans_subcat= ts.id_trans_subcat)
                inner join expense_tracker.transaction_category tc on (t.id_trans_cat=tc.id_trans_cat)
                inner join expense_tracker.transaction_bank_accounts tba on (t.id_trans_ba =tba.id_trans_ba)
                inner join expense_tracker.bank_account_types bat on (tba.id_ba_typ=bat.id_ba_type)
                inner join expense_tracker.bank_account_owner bao on (bat.id_ba_own=bao.id_ba_own)and bao.owner_name = 'Janusz Kowalski';
                
            
 
 discard all;
 explain analyze select * from expense_tracker.Janusz_trasactions_2015_year;
 
 --Seq Scan on janusz_trasactions_2015_year  (cost=0.00..11.50 rows=150 width=498) (actual time=0.042..0.089 rows=256 loops=1)
--Planning Time: 0.617 ms
--Execution Time: 0.119 ms

 --3 Partycjonowanie tabeli transakcji ze względu na rok (zadziała w przypadku gdy będziemy szukać po zakresie datowym)
discard all;
 explain analyze select 
            tc.category_name, ts.subcategory_name, tt.transaction_type_name, t.transaction_date,
            extract (year from t.transaction_date) trans_year, t.transaction_value, bat.ba_type
            from expense_tracker.transactions t 
                inner join expense_tracker.transaction_type tt on (t.id_trans_type =tt.id_trans_type) and extract(year from t.transaction_date)=2015
                inner join expense_tracker.transaction_subcategory ts on (t.id_trans_subcat= ts.id_trans_subcat)
                inner join expense_tracker.transaction_category tc on (t.id_trans_cat=tc.id_trans_cat)
                inner join expense_tracker.transaction_bank_accounts tba on (t.id_trans_ba =tba.id_trans_ba)
                inner join expense_tracker.bank_account_types bat on (tba.id_ba_typ=bat.id_ba_type)
                inner join expense_tracker.bank_account_owner bao on (bat.id_ba_own=bao.id_ba_own)and bao.owner_name = 'Janusz Kowalski'
                where t.transaction_date between '2017-07-01' and '2017-09-01';
--Planning Time: 3.025 ms
--Execution Time: 0.763 ms

    CREATE TABLE IF NOT EXISTS EXPENSE_TRACKER.TRANSACTIONS_PARTITIONED ( 
        ID_TRANSACTION serial, 
        ID_TRANS_BA integer REFERENCES EXPENSE_TRACKER.TRANSACTION_BANK_ACCOUNTS (ID_TRANS_BA), 
        ID_TRANS_CAT integer REFERENCES EXPENSE_TRACKER.TRANSACTION_CATEGORY (ID_TRANS_CAT), 
        ID_TRANS_SUBCAT integer REFERENCES EXPENSE_TRACKER.TRANSACTION_SUBCATEGORY (ID_TRANS_SUBCAT),
        ID_TRANS_TYPE integer REFERENCES EXPENSE_TRACKER.TRANSACTION_TYPE (ID_TRANS_TYPE), 
        ID_USER integer REFERENCES EXPENSE_TRACKER.USERS (ID_USER), 
        TRANSACTION_DATE date default current_date, 
        TRANSACTION_VALUE numeric(9,2), 
        TRANSACTION_DESCRIPTION text, INSERT_DATE timestamp default current_timestamp, 
        UPDATE_DATE timestamp default current_timestamp,
        primary key (ID_TRANSACTION, TRANSACTION_DATE) )
        PARTITION BY RANGE(TRANSACTION_DATE);
    
CREATE TABLE transactions_y2015 PARTITION OF EXPENSE_TRACKER.TRANSACTIONS_PARTITIONED FOR VALUES FROM ('2015-01-01') TO ('2016-01-01'); 
CREATE TABLE transactions_y2016 PARTITION OF EXPENSE_TRACKER.TRANSACTIONS_PARTITIONED FOR VALUES FROM ('2016-01-01') TO ('2017-01-01'); 
CREATE TABLE transactions_y2017 PARTITION OF EXPENSE_TRACKER.TRANSACTIONS_PARTITIONED FOR VALUES FROM ('2017-01-01') TO ('2018-01-01'); 
CREATE TABLE transactions_y2018 PARTITION OF EXPENSE_TRACKER.TRANSACTIONS_PARTITIONED FOR VALUES FROM ('2018-01-01') TO ('2019-01-01');
 
insert into transactions_y2017 (select * from expense_tracker.transactions where transaction_date between '2017-07-01' and '2017-09-01');

explain analyze select 
            tc.category_name, ts.subcategory_name, tt.transaction_type_name, t.transaction_date,
            extract (year from t.transaction_date) trans_year, t.transaction_value, bat.ba_type
            from expense_tracker.transactions_partitioned t 
                inner join expense_tracker.transaction_type tt on (t.id_trans_type =tt.id_trans_type) and extract(year from t.transaction_date)=2015
                inner join expense_tracker.transaction_subcategory ts on (t.id_trans_subcat= ts.id_trans_subcat)
                inner join expense_tracker.transaction_category tc on (t.id_trans_cat=tc.id_trans_cat)
                inner join expense_tracker.transaction_bank_accounts tba on (t.id_trans_ba =tba.id_trans_ba)
                inner join expense_tracker.bank_account_types bat on (tba.id_ba_typ=bat.id_ba_type)
                inner join expense_tracker.bank_account_owner bao on (bat.id_ba_own=bao.id_ba_own)and bao.owner_name = 'Janusz Kowalski'
                where t.transaction_date between '2017-07-01' and '2017-09-01';

  --Join Filter: (bat.id_ba_own = bao.id_ba_own)
  --->  Nested Loop  (cost=10.04..16.47 rows=1 width=486) (actual time=0.335..0.337 rows=0 loops=1)
    --    Join Filter: (tba.id_ba_typ = bat.id_ba_type)
      --  ->  Nested Loop  (cost=10.04..15.31 rows=1 width=368) (actual time=0.335..0.337 rows=0 loops=1)
        --      Join Filter: (t.id_trans_ba = tba.id_trans_ba)
          --    ->  Nested Loop  (cost=10.04..14.15 rows=1 width=368) (actual time=0.334..0.336 rows=0 loops=1)
            --        Join Filter: (t.id_trans_cat = tc.id_trans_cat)
              --      ->  Nested Loop  (cost=10.04..12.91 rows=1 width=254) (actual time=0.334..0.336 rows=0 loops=1)
                          --Join Filter: (t.id_trans_type = tt.id_trans_type)
                          --->  Hash Join  (cost=10.04..11.79 rows=1 width=140) (actual time=0.334..0.335 rows=0 loops=1)
                        --        Hash Cond: (ts.id_trans_subcat = t.id_trans_subcat)
                      --          ->  Seq Scan on transaction_subcategory ts  (cost=0.00..1.54 rows=54 width=122) (actual time=0.052..0.052 rows=1 loops=1)
                    --            ->  Hash  (cost=10.03..10.03 rows=1 width=26) (actual time=0.272..0.272 rows=0 loops=1)
                  --                    Buckets: 1024  Batches: 1  Memory Usage: 8kB
                --                      ->  Seq Scan on transactions_y2017 t  (cost=0.00..10.03 rows=1 width=26) (actual time=0.271..0.271 rows=0 loops=1)
              --                              Filter: ((transaction_date >= '2017-07-01'::date) AND (transaction_date <= '2017-09-01'::date) AND (date_part('year'::text, (transaction_date)::timestamp without time zone) = '2015'::double precision))
            --                                Rows Removed by Filter: 268
          --                ->  Seq Scan on transaction_type tt  (cost=0.00..1.05 rows=5 width=122) (never executed)
        --            ->  Seq Scan on transaction_category tc  (cost=0.00..1.11 rows=11 width=122) (never executed)
      --        ->  Seq Scan on transaction_bank_accounts tba  (cost=0.00..1.07 rows=7 width=8) (never executed)
    --    ->  Seq Scan on bank_account_types bat  (cost=0.00..1.07 rows=7 width=126) (never executed)
  --->  Seq Scan on bank_account_owner bao  (cost=0.00..1.04 rows=1 width=4) (never executed)
  --      Filter: ((owner_name)::text = 'Janusz Kowalski'::text)
--Planning Time: 4.551 ms
--Execution Time: 0.449 ms
--4
 --Zołożyłem, że użytkownik bazy danych, będzie chciał wyszukać transakcje po kategorii, imoże nie pamiętać lub nie wiedzieć, jak dokladnie jest jej nazwa
 --próbowałem użyć trigramu, ale coś do końca mi nie wychodzi baza dalej wykonuje scan sekwencyjny nie biorąc po uwagę indexu, może w tabeli za krótki ciąg znaków lub za mało rekordów na taki index?
 -- podobnie z TSVECTOR co prawda przy trigger-e nie zmieniałem języka na polski bo poczytalem jak to trzeba zrobić i zrezygnowałem, aangielski zapewne korzysta tylko z tablicy ASCII
 discard all;
 EXPLAIN ANALYZE
select * from expense_tracker.transactions t inner join expense_tracker.transaction_category tc on (t.id_trans_cat=tc.id_trans_cat)
 where tc.category_name like '%Jedz%';
 
  --explain analyze select * from expense_tracker.transaction_category where category_name like '%ZDR%';
 --Hash Join  (cost=1.15..263.54 rows=649 width=716) (actual time=0.069..3.738 rows=2454 loops=1)
  --Hash Cond: (t.id_trans_cat = tc.id_trans_cat)
  --->  Seq Scan on transactions t  (cost=0.00..236.42 rows=7142 width=54) (actual time=0.027..1.052 rows=7142 loops=1)
  --->  Hash  (cost=1.14..1.14 rows=1 width=662) (actual time=0.029..0.031 rows=1 loops=1)
    --    Buckets: 1024  Batches: 1  Memory Usage: 9kB
      --  ->  Seq Scan on transaction_category tc  (cost=0.00..1.14 rows=1 width=662) (actual time=0.022..0.025 rows=1 loops=1)
        --      Filter: ((category_name)::text ~~ 'JEDZ%'::text)
          --    Rows Removed by Filter: 10
--Planning Time: 0.335 ms
--Execution Time: 3.949 ms
  
CREATE EXTENSION pg_trgm;


CREATE INDEX category_name_indx ON expense_tracker.transaction_category USING GIN(category_name gin_trgm_ops);
--ALTER TABLE expense_tracker.transaction_category ADD COLUMN tc_category_name TSVECTOR;
--CREATE INDEX category_descryption_indx ON expense_tracker.transaction_category USING GIN(category_description gin_trgm_ops);
--CREATE INDEX category_name_indx2 ON expense_tracker.transaction_category USING GIN(tc_category_name);
--select * from expense_tracker.transactions t inner join expense_tracker.transaction_category tc on (t.id_trans_cat=tc.id_trans_cat)
-- where tc.category_name @@ to_tsquery('jedz');
  --CREATE TRIGGER tc_category_name
   --BEFORE INSERT OR UPDATE ON expense_tracker.transaction_category
    --FOR EACH ROW EXECUTE PROCEDURE 
     --tsvector_update_trigger(tc_category_name, 'pg_catalog.english', category_name);      
            
--update expense_tracker.transaction_category set category_name ='OSZCZĘDNOŚCI' where id_trans_cat =10;

--5
-- Po za opisanymi powyżej, próbowałem jescze :
-- zdefiniować zwykły widok dla transacji roku bieżącego dla każdego właściciela osobno;
-- utworzyć indeksy na tabelach transaction_category->category_name, oraz transaction_subcategory->subcategory_name;
-- ale w żadnym z zapytań, które testowałem nie było "wielkiej" różnicy ( kilka milisekund)- być może źle dobrałem przykłady.
-- początkowo miałem też pomysł na to co Ty, też podpowiedziałeś czyli partycjonowanie tabeli transakcji ze względu na rok.

