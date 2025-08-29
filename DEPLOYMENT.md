


># +A_DevAfrica Deployment Guide

This guide provides detailed instructions for deploying the +A_DevAfrica platform to Render.

## 1. Prerequisites

Before you begin, ensure you have:

*   A Render account.
*   A Supabase account.
*   A Stripe account (and M-Pesa if applicable).
*   The project code pushed to a GitHub repository.

## 2. Supabase Setup

1.  **Create a new project** in your Supabase dashboard.
2.  **Database**: Note the database connection string (URI). You will use this for the `DATABASE_URL` environment variable.
3.  **Storage**: Create a new bucket for file uploads (e.g., `project-media`).
4.  **API Keys**: Find your `SUPABASE_URL`, `SUPABASE_ANON_KEY`, and `SUPABASE_SERVICE_ROLE_KEY` in the API settings.
5.  **Extensions**: If you need geospatial queries, enable the `postgis` extension in the database settings.

## 3. Redis Setup

1.  On Render, create a new **Redis** instance.
2.  Note the Redis connection URL. This will be your `REDIS_URL` environment variable.

## 4. Render Setup

We will create two services on Render: one for the web application and one for the Sidekiq background worker.

### 4.1. Web Service (Rails App)

1.  Create a new **Web Service** on Render.
2.  Connect your GitHub repository.
3.  **Settings**:
    *   **Name**: `adevafrica-web` (or similar)
    *   **Environment**: Ruby
    *   **Build Command**: `bundle install && yarn install && rails assets:precompile`
    *   **Start Command**: `bundle exec rails s`

4.  **Environment Variables**:
    Add the following environment variables in the Render dashboard:

    *   `RAILS_ENV`: `production`
    *   `DATABASE_URL`: (from Supabase)
    *   `SUPABASE_URL`: (from Supabase)
    *   `SUPABASE_SERVICE_ROLE_KEY`: (from Supabase)
    *   `SUPABASE_ANON_KEY`: (from Supabase)
    *   `SECRET_KEY_BASE`: (generate a new one with `rails secret`)
    *   `REDIS_URL`: (from Render Redis)
    *   `STRIPE_SECRET_KEY`: (from Stripe)
    *   `STRIPE_PUBLISHABLE_KEY`: (from Stripe)
    *   `MPESA_CLIENT_ID`: (from M-Pesa)
    *   `MPESA_CLIENT_SECRET`: (from M-Pesa)
    *   `MAPBOX_API_KEY`: (from Mapbox)
    *   `ASSISTANT_API_KEY`: (from your LLM provider)

### 4.2. Worker Service (Sidekiq)

1.  Create a new **Background Worker** on Render.
2.  Connect the same GitHub repository.
3.  **Settings**:
    *   **Name**: `adevafrica-worker` (or similar)
    *   **Environment**: Ruby
    *   **Build Command**: `bundle install && yarn install`
    *   **Start Command**: `bundle exec sidekiq -C config/sidekiq.yml`

4.  **Environment Variables**:
    Copy the same environment variables from the web service.

## 5. Webhook Configuration

1.  **Stripe**: In your Stripe dashboard, go to **Developers > Webhooks**.
2.  Add a new endpoint with the URL `https://your-render-app-url.onrender.com/api/v1/payments/webhook`.
3.  Select the events to listen for (e.g., `checkout.session.completed`).
4.  Note the webhook signing secret and add it as an environment variable (`STRIPE_WEBHOOK_SECRET`).

## 6. Domain & SSL

1.  In the Render dashboard for your web service, go to **Settings > Custom Domains**.
2.  Add your custom domain and follow the instructions to configure your DNS records.
3.  Render will automatically provision an SSL certificate for your domain.

## 7. Deployment Trigger

By default, Render will automatically deploy your application whenever you push to the `main` branch of your GitHub repository. You can configure this in the service settings.



## 8. Automated Deployment with Render

The project includes a `render.yaml` file for automated deployment:

1. **Fork or clone the repository** to your GitHub account
2. **Connect to Render**: 
   - Go to [render.com](https://render.com) and sign up/login
   - Connect your GitHub account
   - Create a new "Blueprint" and select this repository
3. **Environment Variables**: Set the following in Render dashboard:
   - `STRIPE_SECRET_KEY`: Your Stripe secret key
   - `STRIPE_PUBLISHABLE_KEY`: Your Stripe publishable key
   - `SUPABASE_URL`: Your Supabase project URL
   - `SUPABASE_SERVICE_ROLE_KEY`: Your Supabase service role key
   - `SUPABASE_ANON_KEY`: Your Supabase anonymous key
   - `MAPBOX_API_KEY`: Your Mapbox API key
   - `ASSISTANT_API_KEY`: Your AI assistant API key (OpenAI/Mistral)
4. **Deploy**: Render will automatically deploy the web service and worker

## 9. Local Development Setup

To run the application locally:

```bash
# Clone the repository
git clone [your-repo-url]
cd adevafrica

# Install dependencies
bundle install
yarn install

# Set up environment variables
cp .env.example .env
# Edit .env with your actual values

# Set up database
rails db:create
rails db:migrate
rails db:seed

# Start Redis (for Sidekiq)
redis-server

# Start Sidekiq worker (in separate terminal)
bundle exec sidekiq -C config/sidekiq.yml

# Start Rails server
rails server
```

## 10. Production Checklist

Before going live:

- [ ] Set up SSL certificate (automatic with Render)
- [ ] Configure custom domain
- [ ] Set up monitoring and logging
- [ ] Configure backup strategy for database
- [ ] Set up error tracking (e.g., Sentry)
- [ ] Configure email delivery (SMTP)
- [ ] Set up analytics (Google Analytics)
- [ ] Test all payment flows
- [ ] Verify webhook endpoints
- [ ] Load test the application
- [ ] Set up staging environment

## 11. Maintenance

Regular maintenance tasks:

- Monitor application performance
- Update dependencies regularly
- Review and rotate API keys
- Monitor database performance
- Review and optimize Sidekiq jobs
- Monitor payment processing
- Review security logs
- Update documentation

For support, contact: support@adevafrica.com

