# Serves the built frontend single-page app for any non-API GET request,
# so the Rails server can host both the JSON API and the UI on one port.
class SpaController < ActionController::Base
  def index
    index_file = Rails.public_path.join("index.html")

    if File.exist?(index_file)
      render file: index_file, layout: false
    else
      render plain: "Frontend build not found. Run `npm run build` in frontend/ " \
                    "and copy frontend/dist into backend/public.", status: :not_found
    end
  end
end
