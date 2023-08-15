select location, date, total_cases, new_cases, total_deaths, population
from PortfolioProject..CovidDeaths
where continent is not null
order by 1,2

--look into total cases and death. How many total cases and death do we have per contry?
--what is the % of people who died out of the cases?

select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
from PortfolioProject..CovidDeaths
where continent is not null
order by 1,2

--look into total cases by location. E.g., United States
--Shows the likelihood of facing death in the United States
select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
from PortfolioProject..CovidDeaths
where location like '%states%'
and continent is not null
order by 1,2

--look into countries with the highest infection rate compared to its population
select location, population, MAX(total_cases) as HighestInfectionCount, max((total_cases/population))*100 as PercentPopulationInfected
from PortfolioProject..CovidDeaths
--where location like '%states%'
where continent is not null
Group by Location, population
order by PercentPopulationInfected desc

--look into countries with the highest infection death count per population
select location, MAX(cast(total_deaths as int)) as totalDeathCount
from PortfolioProject..CovidDeaths
where continent is not null
Group by Location
order by totalDeathCount desc

--group by continent
select continent, MAX(cast(total_deaths as int)) as totalDeathCount
from PortfolioProject..CovidDeaths
where continent is not null
Group by continent
order by totalDeathCount desc

--group by location
select location, MAX(cast(total_deaths as int)) as totalDeathCount
from PortfolioProject..CovidDeaths
where continent is null
Group by location
order by totalDeathCount desc

--A look into Worldwide numbers from the first recorded case per day
select date, sum(new_cases) as total_cases, sum (cast(new_deaths as int)) as total_deaths, 
sum(cast(new_deaths as int))/sum(new_cases)*100 as DeathPercentage
from PortfolioProject..CovidDeaths
where continent is not null
group by date
order by 1,2

--A look at total cases, deaths and death%
select sum(new_cases) as total_cases, sum (cast(new_deaths as int)) as total_deaths, 
sum(cast(new_deaths as int))/sum(new_cases)*100 as DeathPercentage
from PortfolioProject..CovidDeaths
where continent is not null
order by 1,2

--Time to join the two tables together -covdi deaths and Covid Vaccination 

select *
from PortfolioProject..CovidDeaths dea 
Join PortfolioProject..CovidVaccination vac 
	on dea.location = vac.location
	and dea.date = vac.date

--A look into the total # of vaccinated people globally per country
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
from PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccination vac 
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
order by 2,3

--looking at the newly vaccinated  by location and date in a way that anytime it gets to a new location
--the #s dont just keep running but restart based on the new contry's data
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, sum(cast(vac.new_vaccinations as int)) over (partition by dea.location)
from PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccination vac 
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
order by 2,3

--another way of doing the above is this
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, sum(convert(int,vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date) as Rolledovervaccinatedpeople
from PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccination vac 
	on dea.location = vac.location
		and dea.date = vac.date
order by 2,3

--calculate the total people vaccinated in a country per population (use CTE
with PopvsVac (continent, location, date, population, New_vaccination, RollingPeopleVaccinated)
as 
(
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, sum(convert(int,vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date) as Rolledovervaccinatedpeople
from PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccination vac 
	on dea.location = vac.location
		and dea.date = vac.date
)
select *, (RollingPeopleVaccinated/population)*100 as totalvaccinated
from PopvsVac

--Create a table

drop table if exists #PercentofVaccinated
create table #PercentofVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccination numeric,
RollingPeopleVaccinated numeric
)
Insert into #PercentofVaccinated
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, sum(convert(int,vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date) as Rolledovervaccinatedpeople
from PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccination vac 
	on dea.location = vac.location
		and dea.date = vac.date
--where dea.continent is not null
select *, (RollingPeopleVaccinated/population)*100 as totalvaccinated
from #PercentofVaccinated


--create view for data visuals
create view PercentofVaccinated as 
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, sum(convert(int,vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date) as Rolledovervaccinatedpeople
from PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccination vac 
	on dea.location = vac.location
		and dea.date = vac.date
where dea.continent is not null

select *
from PercentofVaccinated


--Create a view

drop view if exists InfectedDeathCounts
drop table if exists InfectedDeathCounts
create table #InfectedDeathsCounts
(
location nvarchar(255),
population nvarchar(255),
HighestInfectionCount numeric,
PercentPopulationInfected numeric
)
Insert into #InfectedDeathsCounts
select location, population, MAX(total_cases) as HighestInfectionCount, max((total_cases/population))*100 as PercentPopulationInfected
from PortfolioProject..CovidDeaths
where continent is not null
Group by Location, population
order by PercentPopulationInfected desc;

create view InfectedDeathsCounts as 
select top 100 percent location, population, MAX(total_cases) as HighestInfectionCount, max((total_cases/population))*100 as PercentPopulationInfected
from PortfolioProject..CovidDeaths
where continent is not null
Group by Location, population
 order by PercentPopulationInfected desc;
 
 -- Querries for Tableau vizzies
 --1 (Total cases vs total deaths and Death%
 select sum(new_cases) as total_cases, sum (cast(new_deaths as int)) as total_deaths, 
sum(cast(new_deaths as int))/sum(new_cases)*100 as DeathPercentage
from PortfolioProject..CovidDeaths
where continent is not null
order by 1,2


 -- 2 (To make the analysis consistent some locations are nulled)
select location, sum(cast(new_deaths as int)) as TotalDeathCount
 from PortfolioProject..CovidDeaths
 where continent is null
 and location not in ('world', 'European Union', 'International')
 group by location
 Order by TotalDeathCount desc

 --3
select location, population, MAX(total_cases) as HighestInfectionCount, max((total_cases/population))*100 as PercentPopulationInfected
from PortfolioProject..CovidDeaths
Group by Location, population
order by PercentPopulationInfected desc

--4
select location, population, date, MAX(total_cases) as HighestInfectionCount, max((total_cases/population))*100 as PercentPopulationInfected
from PortfolioProject..CovidDeaths
Group by Location, population, date
order by PercentPopulationInfected desc
