import { execSync } from 'child_process';
import activeAdminPlugin from '@activeadmin/activeadmin/plugin';

const activeAdminPath = execSync('bundle show activeadmin', { encoding: 'utf-8' }).trim();

export default {
  content: [
    "./app/views/**/*.html.erb",
    "./app/helpers/**/*.rb", 
    "./app/assets/stylesheets/**/*.css",
    "./app/javascript/**/*.js",
    // ActiveAdmin paths
    `${activeAdminPath}/app/views/**/*.{arb,erb,html,rb}`,
    './app/admin/**/*.{arb,erb,html,rb}',
    './app/views/active_admin/**/*.{arb,erb,html,rb}',
    './app/views/admin/**/*.{arb,erb,html,rb}',
    './app/views/layouts/active_admin*.{erb,html}',
  ],
  darkMode: "selector",
  plugins: [
    activeAdminPlugin
  ]
}
