require "rails_helper"

RSpec.describe Api::AttendancesController, type: :controller do
  before do
    @user = create(:user)
    @user.confirm
    @user_token = AuthToken.issue_token(user_id: @user.id)
    request.headers["Authorization"] = @user_token
    @course = ScormCourse.create
  end

  describe "POST #create" do
    before do
      student1 = create(:user)
      student2 = create(:user)
      students = [
        {
          name: student1.name,
          sortable_name: student1.name,
          lms_student_id: student1.id,
        },
        {
          name: student2.name,
          sortable_name: student2.name,
          lms_student_id: student2.id,
        },
      ]
      @params = {
        course_id: @course.id,
        lms_course_id: 123,
        date: Date.today,
        status: "PRESENT",
        students: students,
      }
    end

    it "successfully creates an attendance" do
      expect { post :create, @params }.to change { Attendance.count }.by(2)
    end

    it "returns index json" do
      post :create, @params
      expect(response.content_type).to eq("application/json")
    end

    it "successfully updates existing attendance record" do
      params_clone = @params.clone
      post :create, params_clone
      attendances = JSON.parse(response.body)
      expect(attendances.count).to eq(2)
      expect(attendances.first["status"]).to eq("PRESENT")
      expect(attendances.second["status"]).to eq("PRESENT")

      params_clone[:status] = "ABSENT"
      post :create, params_clone
      expect(response).to be_success
      attendances = JSON.parse(response.body)
      expect(attendances.count).to eq(2)
      expect(attendances.first["status"]).to eq("ABSENT")
      expect(attendances.second["status"]).to eq("ABSENT")
    end

    it "successfully deletes existing attendance record" do
      params_clone = @params.clone
      post :create, params_clone

      params_clone[:status] = ""
      students = [
        {
          name: params_clone[:students].first[:name],
          sortable_name: params_clone[:students].first[:name],
          lms_student_id: params_clone[:students].first[:lms_student_id],
        },
      ]
      params_clone[:students] = students
      expect { post :create, params_clone }.to change { Attendance.count }.by(-1)
    end
  end

  describe "GET #search" do
    it "successfully returns the correct attendance record" do
      attendance1 = create(:attendance)
      create(:attendance, date: Date.today - 2.days)
      get :search, course_id: attendance1[:lms_course_id], date: attendance1.date
      expect(assigns(:attendances).count).to eq(1)
      expect(assigns(:attendances).first).to eq(attendance1)
    end

    it "renders json" do
      attendance = create(:attendance)
      get :search, course_id: attendance[:lms_course_id], date: attendance.date
      expect(response.content_type).to eq("application/json")
    end
  end
end
