from crewai import Agent, Task, Crew, Process
from crewai import TaskStatus, TaskResult, TaskError
from crewai import CrewStatus, CrewResult, CrewError
from crewai import ProcessStatus, ProcessResult, ProcessError
from os import environ

os,environ["OPNEAI_API_Key"] = "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"

researcher = Agent(
    name='Researcher',
    goal='Research New AI insights',
    backstory='You are an AI researcher at OpenAI',
    skills=['research', 'writing', 'programming'],
    verbose=True,
    allow_delegation=False
)

writer = Agent(
    name='Writer',
    goal='Write a compelling and engaging blog posts about AI Trends and Insights',
    backstory='You are AI Blog post writer at OpenAI',
    skills=['writing', 'programming'],
    verbose=True,
    allow_delegation=True
)