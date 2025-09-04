# Project Structure

Your repository should be structured as:

- /src - code, internal libraries, and notebooks (such as .ipynb). You must use renv to allow us to reproduce your R environment.
- /data - either the CSV files etc. you are using, or, in case the data file is enormous, some README describing where it can be accessed (e.g., via S3 buckets).
- /test - you are testing, aren't you?
- /doc - prompts, other docs. Prompts should go in the prompts.md file, sorted temporally (by date). If the tool you use (Claude, Copilot etc) has a mechanism for storing prompts/sessions, you can link to that. For example, Cloudflare stores their sessions on a website.
- /paper - the project writeups. Please write these in Quarto. Quarto supports references. You may embed visualizations in your Quarto document directly. You should end up with at least one doc per milestone (e.g., )
- README.md - project team (and Github IDs), topic and related work.
- CHANGELOG.md - your team meetings must be documented in this, capturing what progress transpired each week. Use GitHub commit references to link to the relevant commit/issue/PR.

# Project Advice

Each student/team member is required to do the following:

- Follow any updates on this site, Teams, Brightspace, and meet all of the established interim milestones.
- Attend all the lectures during the semester, as these will prepare you to succeed in this project.
- Together with your team mates (if any), choose a topic for your project.
- Contribute equitably throughout the term to the team project in terms of research, presentation, and paper writing.
- Grade will be determined on a combination of the following:
  - the final report and meeting milestones throughout the term
  - Your grade will also reflect how much you refer to and integrate course concepts throughout the term.
  - Team peer reviews of effort.
  - Extra points may be given for: challenging projects, original ideas, collaboration with external organizations.

# Ways to get bad marks

- Superficial or lazy replication of existing work. Starting from an existing problem is fine, as are replications, but just re-running analysis someone else did is not enough to pass the project.
- Letting LLMs do all the analysis work. You can expect me to ask pointed questions about your assumptions, so your team needs to understand what you are doing.
- Forgetting that this is a short course and explaining you no longer have time to finish the project as originally conceived.
- Writing the report at the end, instead of as you go.
- Do nothing to help your team. I reserve the right to adjust individual marks if there is evidence someone is not contributing. Not having any evidence of your work in GitHub (commits, discussions) would be a problem.
- 