admin = CreateAdminService.create_admin
puts "CREATED ADMIN USER: " << admin.email

# Add an LTI Application
scorm_permissions = "CREATE_ASSIGNMENT,DELETE_ASSIGNMENT,LIST_ASSIGNMENTS"
proct_permissions = %w{
  LIST_USERS_IN_COURSE_USERS
  LIST_QUIZZES_IN_COURSE
  GET_SUB_ACCOUNTS_OF_ACCOUNT
}.join(",")
canvas_permissions = "GET_SINGLE_QUIZ,LIST_QUESTIONS_IN_QUIZ_OR_SUBMISSION,CREATE_CONVERSATION"
lti_applications = [{
  name: "SCORM Player",
  description: "SCORM Player",
  client_application_name: "scorm",
  canvas_api_permissions: scorm_permissions,
}, {
  name: "Attendance",
  description: "Attendance Application",
  client_application_name: "attendance",
  canvas_api_permissions: "LIST_USERS_IN_COURSE_USERS",
}, {
  name: "Proctor Tool",
  description: "Proctor Tool",
  client_application_name: "proctor",
  canvas_api_permissions: proct_permissions
}, {
  name: "Test Administration Tool",
  description: "Test Administration",
  client_application_name: "test_administration",
  canvas_api_permissions: canvas_permissions,
}, {
  name: "Quiz Converter",
  description: "Converts word docs to quizzes",
  client_application_name: "quiz_converter",
  canvas_api_permissions: "",
}, {
  name: "Test Taking Tool",
  description: "Where students take proctored exams",
  client_application_name: "test_taking",
  canvas_api_permissions: "",
}]

lti_consumer_uri = Rails.application.secrets.canvas_url

lti_application_instances = [{
  lti_application: "SCORM Player",
  lti_key: "scorm-player",
  lti_secret: Rails.application.secrets.scorm_lti_secret,
  lti_consumer_uri: lti_consumer_uri,
  canvas_token: Rails.application.secrets.canvas_token,
}, {
  lti_application: "Attendance",
  lti_key: "attendance",
  lti_secret: Rails.application.secrets.attendance_lti_secret,
  lti_consumer_uri: lti_consumer_uri,
  canvas_token: Rails.application.secrets.canvas_token,
}, {
  lti_application: "Proctor Tool",
  lti_key: "proctor-tool",
  lti_secret: Rails.application.secrets.proctor_lti_secret,
  lti_consumer_uri: lti_consumer_uri,
  canvas_token: Rails.application.secrets.canvas_token,
}, {
  lti_application: "Quiz Converter",
  lti_key: "quiz-converter",
  lti_secret: Rails.application.secrets.quiz_converter_lti_secret,
  lti_consumer_uri: lti_consumer_uri,
  canvas_token: Rails.application.secrets.canvas_token,
}, {
  lti_application: "Test Administration Tool",
  lti_key: "test-administration",
  lti_secret: Rails.application.secrets.test_administration_lti_secret,
  lti_consumer_uri: lti_consumer_uri,
  canvas_token: Rails.application.secrets.canvas_token,
}, {
  lti_application: "Test Taking Tool",
  lti_key: "test-taking",
  lti_secret: Rails.application.secrets.test_administration_lti_secret,
  lti_consumer_uri: lti_consumer_uri,
  canvas_token: Rails.application.secrets.canvas_token,
}]

lti_applications.each do |attrs|
  if lti_application = LtiApplication.find_by(name: attrs[:name])
    lti_application.update_attributes!(attrs)
  else
    LtiApplication.create!(attrs)
  end
end

lti_application_instances.each do |attrs|
  lti_application = LtiApplication.find_by(name: attrs.delete(:lti_application))
  attrs = attrs.merge(lti_application_id: lti_application.id)
  if lti_application_instance = LtiApplicationInstance.find_by(lti_key: attrs[:lti_key])
    # Don't change production lti keys
    attrs.delete(:lti_secret) if attrs[:lti_secret].blank? || Rails.env.production?

    lti_application_instance.update_attributes!(attrs)
  else
    LtiApplicationInstance.create!(attrs)
  end
end

Lti::Utils.lti_configs
