--1
select  p.product_name,
        p.product_code,
        pmr.region_name,
        s.*
from products p inner join product_manufactured_region pmr on(p.product_man_region=pmr.id)
                inner join sales s on (p.id=s.sal_prd_id)
                where p.product_code ='PRD8' and (s.sal_date between now()-interval '2'month and now() )

--2
discard all ;
   explain analyze select  p.product_name,
        p.product_code,
        pmr.region_name,
        s.*
from products p inner join product_manufactured_region pmr on(p.product_man_region=pmr.id)
                inner join sales s on (p.id=s.sal_prd_id)
                where p.product_code ='PRD8' and (s.sal_date between now()-interval '2'month and now() ) ;
   --             
--zapytanie zostaÅ‚e rozdzielone na dwa wÄ…tki.
--nastÄ…piÅ‚o sekwencyjen skanowanie po tabeli produkty z warunkiem PRD8 w wyniku zastosowania filtru usuniÄ™to 989 wierszy
--rÃ³wnolegle nastÄ…piÅ‚o sekwencyjne skanowanie tabeli sales z warunkiem dla daty sprzedaÅ¼y wyniki z hashowano (zuÅ¼ycie 9kb pamiÄ™ci) oraz uÅ¼yto algorytmu zÅ‚Ä…czeÅ„ typu hash join 
--dla tabeli sales i produkts z warunkiem zÅ‚Ä…czenia s.sal_prd_id = p.id w wyniku zastosowania filtru usuniÄ™to 8 wierszy
--przeszukano sekwencyjnie tabele pmr i z hash-owano wyniki (zuÅ¼ycie 9kb pamieci) algorytmu zÅ‚Ä…czeÅ„ typu hash join z warunkiem p.product_man_region=pmr.id
-- caÅ‚kowity czas wykonania zapytania 1318.297 ms, czas planowania zapytania 4.387 ms
 

--3
            
select count(distinct product_code) prod_code_quantity,
       count(*) all_rows,
       count (distinct product_code)::float/count(*) as selectivity
    from products;

--4
create index on_product_code_btree on products using BTREE(product_code);

--5
discard all;
explain analyze select  p.product_name,
        p.product_code,
        pmr.region_name,
        s.*
from products p inner join product_manufactured_region pmr on(p.product_man_region=pmr.id)
                inner join sales s on (p.id=s.sal_prd_id)
                where p.product_code ='PRD8' and (s.sal_date between now()-interval '2'month and now() ) ;
                
    --plan zapytania nie wykorzystuje indexu
            
 --6
 
 create index sal_date_index on sales (sal_date);      
 
 --7
 discard all;
explain analyze select  p.product_name,
        p.product_code,
        pmr.region_name,
        s.*
from products p inner join product_manufactured_region pmr on(p.product_man_region=pmr.id) -- duÅ¼a rÃ³Å¼nica w szybkoÅ›ci zapytania z and dla PRD8 w join
                inner join sales s on (p.id=s.sal_prd_id)
                where p.product_code ='PRD8' and (s.sal_date between now()-interval '2'month and now() ) ;
                
-- nadal Å¼aden z indeksÃ³w nie jest uÅ¼yty
            
--8
--insert do tabeli partycjonowanej odbywa się prawie sekunde dłużej.