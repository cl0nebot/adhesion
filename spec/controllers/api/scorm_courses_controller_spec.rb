require "rails_helper"

RSpec.describe Api::ScormCoursesController, type: :controller do
  before do
    @user = FactoryGirl.create(:user)
    @user.confirm
    @user_token = AuthToken.issue_token({ user_id: @user.id })
  end

  before(:example) do
    request.headers["Authorization"] = @user_token
    @mock_scorm = object_double(
      ScormCloudService.new,
      remove_course: { status: 200, response: { removed: true } },
      course_manifest: { status: 200, response: { course: "manifest" } },
      upload_course: { status: 200 },
      list_courses: { status: 200 },
      sync_courses: { test: "data" },
      preview_course: { status: 200, response: { launch_url: "fake_url" } },
    )
    expect(
      controller,
    ).to receive(:scorm_connect_service).at_most(3).times.and_return(@mock_scorm)
  end

  describe "GET index" do
    it "should return unauthorized without auth token" do
      request.headers["Authorization"] = nil
      get :index, course_id: 1
      expect(response).to have_http_status 401
    end

    it "should return authorized with auth token" do
      get :index, course_id: 1
      expect(response).to have_http_status 200
      expect(JSON.parse(response.body)["response"]["test"]).to eq("data")
    end
  end

  describe "POST create" do
    it "should upload scorm package" do
      expect(ScormImportJob).to receive(:perform_later)
      class Foo
        def path; end
      end

      file = Foo.new

      allow(controller).to receive(:copy_to_storage).and_return(file)

      post :create, file: "fake_file", lms_course_id: "course_id"
      expect(response).to have_http_status(200)
    end
  end

  describe "GET show" do
    it "should return course manifest" do
      course = ScormCourse.create
      get :show, id: course.id

      expect(response).to have_http_status 200
      expect(response.body).to include('{"course":"manifest"}')
    end
  end

  describe "PUT update" do
    before do
      canvas_api_permissions = {
        default: [
          "administrator", # Internal (non-LTI) role
          "urn:lti:sysrole:ims/lis/SysAdmin",
          "urn:lti:sysrole:ims/lis/Administrator",
          "urn:lti:role:ims/lis/Instructor",
        ],
        common: [],
        CREATE_ASSIGNMENT: [],
      }
      @application = create(
        :application,
        canvas_api_permissions: canvas_api_permissions,
      )
      @application_instance = create(:application_instance, application: @application)
      allow(controller).to receive(:current_application_instance).and_return(@application_instance)
      allow(Application).to receive(:find_by).with(:lti_key).and_return(@application_instance)

      @user_token = AuthToken.issue_token(
        {
          user_id: @user.id,
          lms_course_id: "123",
          tool_consumer_instance_guid: "123abc",
          context_id: "456def",
        },
      )
      @user_token_header = "Bearer #{@user_token}"
      request.headers["Authorization"] = @user_token_header
    end

    it "should update scorm package" do
      course = ScormCourse.create
      course_params = { points_possible: "50" }
      params = {
        id: course.scorm_service_id,
        scorm_course: course_params,
        scorm_assignment_data: {
          assignment: {
            name: "bfcoder",
            points_possible: course_params[:points_possible],
          },
        },
      }
      put :update, params: params
      expect(course.reload.points_possible).to eq(50.0)
      expect(response.body).to include('"points_possible":50.0')
    end

    it "should create an LtiLaunch" do
      scorm_course = ScormCourse.create(lms_course_id: "123")
      course_params = { points_possible: "100" }
      params = {
        id: scorm_course.scorm_service_id,
        scorm_course: course_params,
        scorm_assignment_data: {
          assignment: {
            name: "bfcoder",
            points_possible: course_params[:points_possible],
          },
        },
      }
      put :update, params: params
      scorm_course.reload
      lti_launch = scorm_course.lti_launch
      expect(lti_launch).to be
      expect(lti_launch.config).to eq(
        {
          scorm_course_id: scorm_course.id,
          scorm_service_id: scorm_course.scorm_service_id,
          lms_course_id: scorm_course.scorm_service_id.split("_").last,
        }.with_indifferent_access,
      )
      expect(lti_launch.tool_consumer_instance_guid).to eq("123abc")
      expect(lti_launch.context_id).to eq("456def")
    end
  end

  describe "DEL destroy" do
    it "removes course" do
      ScormCourse.create scorm_service_id: 1
      expect(@mock_scorm).to receive(:remove_course).with("1")
      delete :destroy, id: 1
      expect(response).to have_http_status(200)
      expect(JSON.parse(response.body)["response"]["removed"]).to equal(true)
    end
  end

  describe "GET preview" do
    it "should return preview url" do
      get :preview, scorm_course_id: 1
      expect(response).to have_http_status 200
      expect(JSON.parse(
        response.body,
      )["response"]).to eq("launch_url" => "fake_url")
    end
  end

  describe "GET status" do
    it "should return the status" do
      scorm_course = create(:scorm_course, import_job_status: "RUNNING")
      get :status, params: { scorm_course_id: scorm_course.id }
      expect(response).to have_http_status 200
      expected = { "scorm_course_id" => scorm_course.id, "status" => "RUNNING" }
      expect(JSON.parse(response.body)).to eq(expected)
    end
  end

  describe "GET course_report" do
    it "should return course analytics data" do
      course = ScormCourse.create
      get :course_report, params: { scorm_course_id: course.scorm_service_id }
      expect(response).to have_http_status 200
      expect(JSON.parse(response.body)).to include("scores")
    end
  end

  describe "GET activity_report" do
    it "should return student course analytics data" do
      course = ScormCourse.create
      get :activity_report, params: { scorm_course_id: course.scorm_service_id }
      expect(response).to have_http_status 200
      expect(JSON.parse(response.body)).to include("analytics_table")
    end
  end
end
