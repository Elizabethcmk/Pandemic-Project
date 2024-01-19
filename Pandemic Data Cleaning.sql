select * from CovidDeaths
order by 3,4

select * from CovidVaccinations
order by 3,4

---selecting the data I'll be using
select location, date, total_cases, new_cases, total_deaths, population 
from CovidDeaths
order by 1,2

-----Total cases vs Total deaths
select location, date, total_cases, total_deaths, (cast(total_deaths as float)/cast(total_cases as float))*100 AS death_percentage
from CovidDeaths
Where location like '%states%'
order by 1,2

---Total cases vs Population
select continent, location, date, total_cases, population, (total_cases)/(population)*100 AS population_infected_percentage
from CovidDeaths
Where location like '%states%'
order by 1,2

-----Infection rates by Population
select continent, population, MAX(total_cases) AS infection_rate, (MAX(total_cases)/population)*100 AS infection_percentage
from CovidDeaths
GROUP BY population, continent
order by infection_percentage desc


----Death count
select continent, location, MAX(cast(total_deaths as int)) AS death_count
from CovidDeaths
WHERE continent IS NOT NULL
Group By location, continent
Order By death_count desc


---Death count By continent
select continent, MAX(cast(total_deaths as int)) AS death_count
from CovidDeaths
WHERE continent IS NOT NULL
Group By continent
Order By death_count desc

---global numbers
select date, SUM(new_cases) AS total_cases, SUM(cast(new_deaths as int)) AS total_deaths, SUM(cast(new_deaths as int))/NULLIF(SUM(new_cases),0)*100 AS death_percentage
from CovidDeaths
Where continent IS NOT NULL
GROUP BY date
order by death_percentage desc 

select SUM(new_cases) AS total_cases, SUM(cast(new_deaths as int)) AS total_deaths, SUM(cast(new_deaths as int))/NULLIF(SUM(new_cases),0)*100 AS death_percentage
from CovidDeaths
Where continent IS NOT NULL
order by death_percentage desc 

---Joining vaccination table and covid deaths table
select * from CovidDeaths dea
JOIN CovidVaccinations vac
ON dea.location = vac.location
and dea.date = vac.date

---total population vs vaccinations
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations from CovidDeaths dea
JOIN CovidVaccinations vac
ON dea.location = vac.location
and dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3

---rolling count (as vaccinations increases)
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS vaccination_count
from CovidDeaths dea
JOIN CovidVaccinations vac
ON dea.location = vac.location
and dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3

---using a CTE 
WITH populationVSvaccination (continent, location, date, population, new_vaccinations, vaccination_count)
AS
(select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS vaccination_count
from CovidDeaths dea
JOIN CovidVaccinations vac
ON dea.location = vac.location
and dea.date = vac.date
WHERE dea.continent IS NOT NULL)

select *, (vaccination_count/population)*100 AS vaccination_increase_percentage from populationVSvaccination

---Creating a temp table
CREATE TABLE #PopulationVaccinatedPercentage
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
vaccination_count numeric
)
INSERT INTO #PopulationVaccinatedPercentage
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS vaccination_count
from CovidDeaths dea
JOIN CovidVaccinations vac
ON dea.location = vac.location
and dea.date = vac.date
WHERE dea.continent IS NOT NULL

select * from #PopulationVaccinatedPercentage

---Views for visualizations
CREATE VIEW PopulationVaccinatedPercentage AS
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS vaccination_count
from CovidDeaths dea
JOIN CovidVaccinations vac
ON dea.location = vac.location
and dea.date = vac.date
WHERE dea.continent IS NOT NULL
