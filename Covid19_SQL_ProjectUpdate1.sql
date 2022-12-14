--Let's take a look at all the data in both tables.
SELECT *
FROM Covid19_DataExplore_Project..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 3,4

SELECT *
FROM Covid19_DataExplore_Project..CovidVaccinations
WHERE continent IS NOT NULL
ORDER BY 3,4



--Exploratory questions to better understand our data.
------------------------------------------------------------------------------------------------------------------------------------------

--Select data that will be the focus for our project.
--I will primarily focus on the United States since that is where I live.
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM Covid19_DataExplore_Project..CovidDeaths
WHERE location = 'United States'
AND continent IS NOT NULL
ORDER BY 1,2


--Calculate total for each country.
--Total cases and deaths
SELECT location, population, MAX(total_cases) as cases_to_date, MAX(total_deaths) as deaths_to_date
FROM Covid19_DataExplore_Project..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population

--Total hospital patients
SELECT location, population, SUM(CAST(hosp_patients as float)) as total_hosp_patients
FROM Covid19_DataExplore_Project..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population

--Total fully vaccinated
SELECT location, MAX(people_fully_vaccinated) as fully_vax_todate
FROM Covid19_DataExplore_Project..CovidVaccinations
WHERE continent IS NOT NULL
GROUP BY location

--Total tests administered and the average postive rate
SELECT location, MAX(total_tests) as tests_completed, ROUND(AVG(CAST(positive_rate as float)),2) as avg_positive_test_rate
FROM Covid19_DataExplore_Project..CovidVaccinations
GROUP BY location



--This query compares the total cases, total deaths, and the percentage of people that died from Covid-19 each day.
--How likely are you to die if you contract covid?
SELECT location, date, total_cases, total_deaths, ROUND((total_deaths/total_cases)*100,2) AS death_percentage
FROM Covid19_DataExplore_Project..CovidDeaths
WHERE location = 'United States'
AND continent IS NOT NULL
ORDER BY 1,2


-- This query compares the total cases vs total population.
-- What percentage of the population tested positive for Covid-19 each day?
SELECT location, date, population, total_cases, ROUND((total_cases/population)*100,2) AS infection_percentage
FROM Covid19_DataExplore_Project..CovidDeaths
WHERE location = 'United States' 
AND continent IS NOT NULL
ORDER BY 1,2



--GLOBAL NUMBERS SECTION
--What countries have the highest infection rate compared to their population?
SELECT location, population, MAX(total_cases) as highest_infection_count, ROUND(MAX((total_cases/population))*100,2) as percent_pop_infected
FROM Covid19_DataExplore_Project..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY percent_pop_infected DESC

--What countries have the highest death count?
SELECT location, MAX(cast(total_deaths as int)) as total_death_count
-- Using cast(...as int) changes the data type for column total_deaths to interger from nvarchar so that the query recognizes the column as numbers.
-- This allows the aggregate function MAX() to work properly.
FROM Covid19_DataExplore_Project..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY total_death_count DESC

--What are the infected/death counts for each continent?
SELECT location, MAX(cast(total_cases as int)) as total_cases_count
FROM Covid19_DataExplore_Project..CovidDeaths
WHERE continent IS NULL
AND location IN ('Europe', 'North America', 'Asia', 'South America', 'European Union', 'Africa', 'Oceania')
GROUP BY location
ORDER BY total_cases_count DESC


SELECT location, MAX(cast(total_deaths as int)) as total_death_count
FROM Covid19_DataExplore_Project..CovidDeaths
WHERE continent IS NULL
AND location IN ('Europe', 'North America', 'Asia', 'South America', 'European Union', 'Africa', 'Oceania')
GROUP BY location
ORDER BY total_death_count DESC

--What are the infected/death counts for each income class?
SELECT location, MAX(cast(total_cases as int)) as total_cases_count
FROM Covid19_DataExplore_Project..CovidDeaths
WHERE continent IS NULL
AND location NOT IN ('Europe', 'North America', 'Asia', 'South America', 'European Union', 'Africa', 'Oceania', 'International')
GROUP BY location
ORDER BY total_cases_count DESC

SELECT location, MAX(cast(total_deaths as int)) as total_death_count
FROM Covid19_DataExplore_Project..CovidDeaths
WHERE continent IS NULL
AND location NOT IN ('Europe', 'North America', 'Asia', 'South America', 'European Union', 'Africa', 'Oceania', 'International')
GROUP BY location
ORDER BY total_death_count DESC


--What are the total cases and total deaths each day worldwide?
SELECT date, SUM(total_cases) as world_total_cases, SUM(cast(total_deaths as int)) as world_total_deaths
FROM Covid19_DataExplore_Project..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1,2


--What are the number of new cases and new deaths by date? 
--What percentage of the world's population died from Covid-19 by date?
SELECT date, SUM(new_cases) as world_new_cases, SUM(cast(new_deaths as int)) as world_new_deaths, 
	ROUND(SUM(cast(new_deaths as int))/SUM(new_cases)*100,2) as world_death_percentage
FROM Covid19_DataExplore_Project..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1,2



--Let's look at both CovidDeath and CovidVaccination data.
--Join covid deaths and covid vaccinations tables.
SELECT *
FROM Covid19_DataExplore_Project..CovidDeaths dea
JOIN Covid19_DataExplore_Project..CovidVaccinations vax
ON dea.location=vax.location AND
	dea.date = vax.date


-- What is the total amount of people vaccinated per day across the world?
-- This query includes running count of vaccinations by country and date.
SELECT dea.continent, dea.location, dea.date, dea.population, vax.new_vaccinations,
	SUM(cast(vax.new_vaccinations as bigint)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as running_vax_count
--Using PARTITION BY ensures that the aggregate function SUM() used for the running count starts over for each country and date instead of just all of the data
--running count total becomes so large that 'bigint' data type is used instead of 'int'
FROM Covid19_DataExplore_Project..CovidDeaths dea
JOIN Covid19_DataExplore_Project..CovidVaccinations vax
ON dea.location=vax.location AND
	dea.date = vax.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3


-- What is the total amount of people vaccinated each day in the United States?
SELECT dea.continent, dea.location, dea.date, dea.population, vax.new_vaccinations,
	SUM(cast(vax.new_vaccinations as bigint)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as running_vax_count
FROM Covid19_DataExplore_Project..CovidDeaths dea
JOIN Covid19_DataExplore_Project..CovidVaccinations vax
ON dea.location=vax.location AND
	dea.date = vax.date
WHERE dea.continent IS NOT NULL
AND dea.location = 'United States'
ORDER BY 2,3


--Create CTE from previous query results for future queries.
WITH pop_vs_vax (continent, location, date, population, new_vaccinations, running_vax_count)
AS
(SELECT dea.continent, dea.location, dea.date, dea.population, vax.new_vaccinations,
	SUM(cast(vax.new_vaccinations as bigint)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as running_vax_count
FROM Covid19_DataExplore_Project..CovidDeaths dea
JOIN Covid19_DataExplore_Project..CovidVaccinations vax
ON dea.location=vax.location AND
	dea.date = vax.date
WHERE dea.continent IS NOT NULL
)


WITH US_pop_vs_vax (continent, location, date, population, new_vaccinations, running_vax_count)
AS
(SELECT dea.continent, dea.location, dea.date, dea.population, vax.new_vaccinations,
	SUM(cast(vax.new_vaccinations as bigint)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as running_vax_count
FROM Covid19_DataExplore_Project..CovidDeaths dea
JOIN Covid19_DataExplore_Project..CovidVaccinations vax
ON dea.location=vax.location AND
	dea.date = vax.date
WHERE dea.continent IS NOT NULL
AND dea.location = 'United States'
AND vax.new_vaccinations IS NOT NULL
)

--What percent of the US population is vaccinated?
--From this query, we can see that vaccines became available in December 2020.
--The results show some values over 100%.
--My guess is that vaccinations reported include could be for either the 1st and 2nd shot since there is no clarification of whether it means 'fully vaccinated'.
WITH US_pop_vs_vax (continent, location, date, population, people_fully_vaccinations, running_vax_count)
AS
(SELECT dea.continent, dea.location, dea.date, dea.population, vax.new_vaccinations,
	SUM(cast(vax.new_vaccinations as bigint)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as running_vax_count
FROM Covid19_DataExplore_Project..CovidDeaths dea
JOIN Covid19_DataExplore_Project..CovidVaccinations vax
ON dea.location=vax.location AND
	dea.date = vax.date
WHERE dea.continent IS NOT NULL
AND dea.location = 'United States'
AND vax.new_vaccinations IS NOT NULL
)
SELECT *, ROUND(running_vax_count/population,4) *100 AS vax_percentage
FROM US_pop_vs_vax


--Create a temp table
DROP TABLE if exists #PercentPeopleVaccinated
CREATE TABLE #PercentPeopleVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
running_vax_count numeric
)

INSERT INTO #PercentPeopleVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vax.new_vaccinations,
	SUM(cast(vax.new_vaccinations as bigint)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as running_vax_count
FROM Covid19_DataExplore_Project..CovidDeaths dea
JOIN Covid19_DataExplore_Project..CovidVaccinations vax
ON dea.location=vax.location AND
	dea.date = vax.date
WHERE dea.continent IS NOT NULL
AND dea.location = 'United States'
AND vax.new_vaccinations IS NOT NULL

SELECT *, ROUND(running_vax_count/population,4) *100 AS vax_percentage
FROM #PercentPeopleVaccinated


--Create a view for later visualizations in Tableau Public
CREATE VIEW PercentPopulationVaccinated as
SELECT dea.continent, dea.location, dea.date, dea.population, vax.new_vaccinations,
	SUM(cast(vax.new_vaccinations as bigint)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as running_vax_count
FROM Covid19_DataExplore_Project..CovidDeaths dea
JOIN Covid19_DataExplore_Project..CovidVaccinations vax
ON dea.location=vax.location AND
	dea.date = vax.date
WHERE dea.continent IS NOT NULL
AND dea.location = 'United States'
AND vax.new_vaccinations IS NOT NULL
