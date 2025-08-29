# +A_DevAfrica Platform

This is the README for the +A_DevAfrica platform, a full-functional Ruby on Rails web application.

## Project Overview

This platform is designed to facilitate various functionalities including project management, investment tracking, voting, AI assistance, and payment integrations (Stripe/M-Pesa). It leverages a Rails backend with Hotwire/Turbo/Tailwind for the frontend, Supabase for Postgres & storage, and Sidekiq for background jobs.

## Quick Start

To get the project up and running locally, follow these steps:

1.  **Clone the repository:**
    ```bash
    git clone [YOUR_REPO_URL]
    cd adevafrica
    ```

2.  **Install dependencies:**
    ```bash
    bundle install
    yarn install
    ```

3.  **Environment Variables:**
    Copy the `.env.example` file to `.env` and fill in the required environment variables:
    ```bash
    cp .env.example .env
    ```
    Refer to the `.env.example` file for a list of necessary variables.

4.  **Database Setup:**
    ```bash
    rails db:create
    rails db:migrate
    rails db:seed
    ```

5.  **Run the application:**
    ```bash
    rails s
    ```

## How to Run Tests

To run the test suite, use the following command:

```bash
bundle exec rspec
```

## Deployment

Deployment is configured for Render. Refer to `DEPLOYMENT.md` for detailed steps.



