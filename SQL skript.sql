
-- tabulka 1
CREATE VIEW v_monika_stumarova_potraviny AS 
SELECT 
	YEAR (cp.date_from) AS rok,
	round(avg (cp.value),0) AS prum_cena_potravina,
	cpc.name AS nazev_potravina
FROM czechia_price cp 
JOIN czechia_price_category cpc ON
	cp.category_code = cpc.code 
GROUP BY 
	YEAR(cp.date_from),
	cpc.name;
	

CREATE VIEW v_monika_stumarova_odvetvi AS 
SELECT 
	cp.payroll_year AS rok,
	round (avg(cp.value),0) AS prumerna_mzda,
	cpib.name AS nazev_odvetvi
FROM czechia_payroll cp 
JOIN czechia_payroll_value_type cpvt ON
	cp.value_type_code = cpvt.code AND 
	cp.value_type_code = 5958
JOIN czechia_payroll_calculation cpc ON
	cp.calculation_code = cpc.code AND 
	cp.calculation_code = 100
JOIN czechia_payroll_industry_branch cpib ON
	cp.industry_branch_code = cpib.code
GROUP BY cp.payroll_year, cpib.name;


CREATE TABLE t_monika_stumarova_project_SQL_primary_final AS 
SELECT 
	vmso.rok AS rok,
	vmso.nazev_odvetvi AS odvetvi,
	vmso.prumerna_mzda AS prumerna_mzda,
	vmsp.nazev_potravina AS potravina_nazev,
	vmsp.prum_cena_potravina AS potravina_prum_cena
FROM v_monika_stumarova_odvetvi vmso 
JOIN v_monika_stumarova_potraviny vmsp  ON
	vmso.rok = vmsp.rok
ORDER BY vmso.rok, vmsp.nazev_potravina ;

-- otazka 1

CREATE VIEW v_monika_stumarova_mzdy_2006 AS 
SELECT 
	rok,
	vmso.nazev_odvetvi AS odvetvi,
	prumerna_mzda 
FROM v_monika_stumarova_odvetvi vmso 
WHERE rok = 2006
GROUP BY vmso.nazev_odvetvi ;


CREATE VIEW v_monika_stumarova_mzdy_2018 AS 
SELECT 
	rok,
	vmso.nazev_odvetvi AS odvetvi,
	prumerna_mzda 
FROM v_monika_stumarova_odvetvi vmso 
WHERE rok = 2018
GROUP BY vmso.nazev_odvetvi ;


SELECT 
	vmsm.rok,
	vmsm.prumerna_mzda AS prum_mzda_2006,
	vmsm2.rok,
	vmsm2.prumerna_mzda AS prum_mzda_2018,
	vmsm.odvetvi,
	round((vmsm2.prumerna_mzda-vmsm.prumerna_mzda)/vmsm.prumerna_mzda*100,2) AS zmena_mzdy_procenta
FROM v_monika_stumarova_mzdy_2006 vmsm  
JOIN v_monika_stumarova_mzdy_2018 vmsm2  ON
	vmsm.odvetvi = vmsm2.odvetvi
ORDER BY zmena_mzdy_procenta DESC ;

SELECT 
	tmspspf2.rok +1 AS predchozi_rok,
	tmspspf.rok,
	tmspspf.odvetvi,
	round((tmspspf.prumerna_mzda-tmspspf2.prumerna_mzda)/tmspspf2.prumerna_mzda *100,2) AS zmena_mzdy_procenta
FROM t_monika_stumarova_project_sql_primary_final tmspspf 
JOIN t_monika_stumarova_project_sql_primary_final tmspspf2 ON
	 tmspspf.odvetvi = tmspspf2.odvetvi 
	 AND tmspspf.rok = tmspspf2.rok + 1  
	 AND tmspspf.rok <= 2018
GROUP BY tmspspf.odvetvi, tmspspf.rok 
ORDER BY zmena_mzdy_procenta;

SELECT 
	rok, odvetvi, prumerna_mzda 
FROM t_monika_stumarova_project_sql_primary_final tmspspf 
WHERE odvetvi = 'Peněžnictví a pojišťovnictví'
GROUP BY rok;

SELECT 
	rok, odvetvi, prumerna_mzda 
FROM t_monika_stumarova_project_sql_primary_final tmspspf 
WHERE odvetvi = 'Těžba a dobývání'
GROUP BY rok;


-- otazka 2

SELECT 
	rok,
	potravina_nazev,
	avg(potravina_prum_cena) AS prumer_cena,
	round(avg(prumerna_mzda),0) AS mzdy_prumer_celk,
	round(avg(prumerna_mzda)/avg(potravina_prum_cena),0) AS moznost_koupit
FROM t_monika_stumarova_project_sql_primary_final tmspspf
WHERE rok IN ('2006','2018') 
	AND potravina_nazev IN('Mléko polotučné pasterované', 'Chléb konzumní kmínový')
GROUP BY potravina_nazev, rok ;



-- otazka 3

SELECT 
	tmspspf2.rok +1 AS predchozi_rok,
	tmspspf.rok,
	tmspspf.potravina_nazev,
	round((tmspspf.potravina_prum_cena-tmspspf2.potravina_prum_cena)/tmspspf2.potravina_prum_cena*100,2) AS zmena_ceny_proc
FROM t_monika_stumarova_project_sql_primary_final tmspspf 
JOIN t_monika_stumarova_project_sql_primary_final tmspspf2 ON
	 tmspspf.potravina_nazev = tmspspf2.potravina_nazev  
	 AND tmspspf.rok = tmspspf2.rok + 1  
	 AND tmspspf.rok <= 2018
GROUP BY tmspspf.rok, tmspspf.potravina_nazev
ORDER BY zmena_ceny_proc;

SELECT rok, potravina_nazev, potravina_prum_cena 
FROM t_monika_stumarova_project_sql_primary_final tmspspf 
WHERE potravina_nazev = 'Rajská jablka červená kulatá'
GROUP BY rok;


-- otazka 4

SELECT 
	tmspspf2.rok +1 AS predchozi_rok,
	tmspspf.rok,
	round((SUM(tmspspf.potravina_prum_cena)- SUM(tmspspf2.potravina_prum_cena))/ SUM(tmspspf2.potravina_prum_cena)*100,2) AS zmena_ceny_proc,
CASE 
	WHEN round((SUM(tmspspf.potravina_prum_cena)-SUM(tmspspf2.potravina_prum_cena))/SUM(tmspspf2.potravina_prum_cena)*100,2) > 10 THEN 'Nárust ceny je vyšší než růst mezd'
	ELSE 'není vyšší'
END AS rust_cen_vuci_mzde	
FROM t_monika_stumarova_project_sql_primary_final tmspspf 
JOIN t_monika_stumarova_project_sql_primary_final tmspspf2 ON
	 tmspspf.rok = tmspspf2.rok + 1  
	 AND tmspspf.rok <= 2018
GROUP BY tmspspf.rok 
ORDER BY tmspspf.rok; 


-- tabulka 2

CREATE TABLE t_monika_stumarova_project_sql_secondary_final AS 
SELECT 
	e.`year` AS rok, 
	c.country AS zeme,
	e.population AS populace,
	e.GDP AS HDP,
	e.gini AS gini
FROM countries c 
JOIN economies e ON
	c.country = e.country
WHERE c.continent = 'Europe'
ORDER BY c.country, e.`year` ;



-- otazka 5

SELECT 
	tmspssf2.rok +1 AS predchozi_rok,
	tmspssf.rok,
	tmspssf.zeme,
	round((tmspssf.HDP-tmspssf2.HDP)/tmspssf2.HDP*100,2) AS zmena_HDP_perc
FROM t_monika_stumarova_project_sql_secondary_final tmspssf 
JOIN t_monika_stumarova_project_sql_secondary_final tmspssf2  ON
	 tmspssf.zeme = tmspssf2.zeme  
	 AND tmspssf.rok = tmspssf2.rok + 1  
	 AND tmspssf.zeme = 'Czech Republic' 
	 AND round((tmspssf.HDP-tmspssf2.HDP)/tmspssf2.HDP*100,2) IS NOT NULL 
ORDER BY tmspssf2.rok ;

SELECT 
	rok, zeme, HDP 
FROM t_monika_stumarova_project_sql_secondary_final tmspssf 
WHERE zeme = 'Czech Republic' AND HDP IS NOT NULL 
ORDER BY rok;



CREATE VIEW v_monika_stumarova_zmena_ceny_mzdy_mezirocne AS 
SELECT 
	tmspspf2.rok +1 AS predchozi_rok,
	tmspspf.rok,
	round((sum(tmspspf.potravina_prum_cena)-sum(tmspspf2.potravina_prum_cena))/sum(tmspspf2.potravina_prum_cena)*100,2) AS zmena_ceny_perc,
	round((sum(tmspspf.prumerna_mzda)-sum(tmspspf2.prumerna_mzda))/sum(tmspspf2.prumerna_mzda)*100,2) AS zmena_mzdy_perc
FROM t_monika_stumarova_project_sql_primary_final tmspspf 
JOIN t_monika_stumarova_project_sql_primary_final tmspspf2 ON
	 tmspspf.potravina_nazev = tmspspf2.potravina_nazev  
	 AND tmspspf.rok = tmspspf2.rok + 1  
	 AND tmspspf.rok <= 2018
GROUP BY tmspspf.rok;


SELECT 
	tmspssf2.rok +1 AS predchozi_rok,
	tmspssf.rok,
	tmspssf.zeme,
	round((tmspssf.HDP-tmspssf2.HDP)/tmspssf2.HDP*100,2) AS zmena_HDP_perc,
	vmszcmm.zmena_ceny_perc AS zmena_ceny_perc, 
	vmszcmm.zmena_mzdy_perc AS zmena_mzdy_perc 
FROM t_monika_stumarova_project_sql_secondary_final tmspssf 
JOIN t_monika_stumarova_project_sql_secondary_final tmspssf2  ON
	 tmspssf.zeme = tmspssf2.zeme  
	 AND tmspssf.rok = tmspssf2.rok + 1  
	 AND tmspssf.zeme = 'Czech Republic' 
	 AND round((tmspssf.HDP-tmspssf2.HDP)/tmspssf2.HDP*100,2) IS NOT NULL 
JOIN v_monika_stumarova_zmena_ceny_mzdy_mezirocne vmszcmm ON 
	vmszcmm.rok = tmspssf.rok 
ORDER BY tmspssf2.rok ;


