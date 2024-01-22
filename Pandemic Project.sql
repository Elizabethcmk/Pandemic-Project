---selecting the data I'm going to use
SELECT location, date, total_cases, new_cases, total_deaths, population 
FROM PortfolioProjects..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2

---Total cases vs Total deaths for death percentage (likelihood of dying if disease is contracted)
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS death_percentage
FROM PortfolioProjects..CovidDeaths
WHERE location LIKE '%south afri%'
ORDER BY 1,2

---Total cases vs Population (what percentage of the population got covid)
SELECT location, date, population, total_cases, (total_cases/population) AS total_cases_by_population_percentage
FROM PortfolioProjects..CovidDeaths
WHERE continent IS NOT NULL
---WHERE location LIKE '%south afri%'
ORDER BY 1,2

---Countries with the highest infection rates compared to the population
SELECT location, population, MAX(total_cases) AS highest_infection_count, MAX((total_cases/population))*100 AS infected_population_percentage
FROM PortfolioProjects..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY infected_population_percentage desc

---BREAKING THINGS DOWN BY CONTINENT

---Continents with the highest death count
SELECT continent, MAX(CONVERT(bigint,total_deaths)) AS total_death_count
FROM PortfolioProjects..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY total_death_count desc

---Global numbers
SELECT date, SUM(new_cases) AS sum_of_new_cases, SUM(CAST(new_deaths as int)) AS sum_of_new_deaths, SUM(CAST(new_deaths as int))/SUM(new_cases)*100 AS  global_death_percentage
FROM PortfolioProjects..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1,2


---Joining Vaccinations and Deaths Table

SELECT * FROM PortfolioProjects..CovidDeaths AS dea
JOIN PortfolioProjects..CovidVaccinations AS vac
ON dea.location = vac.location
and dea.date = vac.date

---Total population vs total vaccinations
SELECT dea.continent, dea.location, dea.date, vac.new_vaccinations
FROM PortfolioProjects..CovidDeaths AS dea
JOIN PortfolioProjects..CovidVaccinations AS vac
ON dea.location = vac.location
and dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3

---Rolling count of vaccinations
SELECT dea.continent, dea.location, dea.date, dea.population, SUM(CONVERT(int, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_count_of_vaccinations
FROM PortfolioProjects..CovidDeaths AS dea
JOIN PortfolioProjects..CovidVaccinations AS vac
ON dea.location = vac.location
and dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3

---Using a CTE 
WITH populationVSvaccination (continent, location, date, population, rolling_count_of_vaccinations)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, SUM(CONVERT(int, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_count_of_vaccinations
FROM PortfolioProjects..CovidDeaths AS dea
JOIN PortfolioProjects..CovidVaccinations AS vac
ON dea.location = vac.location
and dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3 OFFSET 0 ROWS
)
SELECT *, (rolling_count_of_vaccinations/population)*100 AS rolling_vaccinations_percentage FROM populationVSvaccination

---Using a temp table for vaccination percentages by population
DROP TABLE IF EXISTS #Peoples_vaccinated_percentages
CREATE TABLE #Peoples_vaccinated_percentages(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
rolling_count_of_vaccinations numeric
)

INSERT INTO #Peoples_vaccinated_percentages
SELECT dea.continent, dea.location, dea.date, dea.population, SUM(CONVERT(int, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_count_of_vaccinations
FROM PortfolioProjects..CovidDeaths AS dea
JOIN PortfolioProjects..CovidVaccinations AS vac
ON dea.location = vac.location
and dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3 OFFSET 0 ROWS

SELECT *, (rolling_count_of_vaccinations/population)*100 AS rolling_vaccinations_percentage FROM #Peoples_vaccinated_percentages

---Using a temp table for total deaths by continent
DROP TABLE IF EXISTS #highest_death_counts_by_continent
CREATE TABLE #highest_death_counts_by_continent(
continent nvarchar(255),
total_death_count bigint
)

INSERT INTO #highest_death_counts_by_continent
SELECT continent, MAX(CONVERT(bigint,total_deaths)) AS total_death_count
FROM PortfolioProjects..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY total_death_count desc

SELECT * FROM #highest_death_counts_by_continent

---Creating views to store data for Tableau
CREATE VIEW Peoples_vaccinated_percentages AS
SELECT dea.continent, dea.location, dea.date, dea.population, SUM(CONVERT(int, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_count_of_vaccinations
FROM PortfolioProjects..CovidDeaths AS dea
JOIN PortfolioProjects..CovidVaccinations AS vac
ON dea.location = vac.location
and dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3 OFFSET 0 ROWS

CREATE VIEW highest_death_counts_by_continent AS
SELECT continent, MAX(CONVERT(bigint,total_deaths)) AS total_death_count
FROM PortfolioProjects..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
--ORDER BY total_death_count desc