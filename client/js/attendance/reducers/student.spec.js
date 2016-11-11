import { ATTENDANCE_STATES, initialState } from './student';
import studentReducer                      from './student';
import { DONE }                            from "../constants/wrapper";
import { list_users_in_course_users }      from "../libs/canvas/constants/courses";


describe('GET_STUDENTS_DONE', () => {
  const students = [{name:"Jack", id:1}, {name:"Jill", id:2}, {name:"Humpty", id:3}, {name:"Dumpty", id:4}];
  const otherStudents = [{name:"Jack", id:5}, {name:"Jill", id:6}, {name:"Humpty", id:7}, {name:"Dumpty", id:8}];

  it('updates all students', () => {
    const action = {
      type: list_users_in_course_users.type + DONE,
      payload:students
    };
    const result = studentReducer(initialState(), action);

    expect(Object.keys(result.all).length).toEqual(4);
    expect(Object.keys(result.all)).toEqual(['1','2','3','4']);
  });

  it('adds appends new students to existing students', () => {
    const action = {
      type: list_users_in_course_users.type + DONE,
      payload:students
    };
    const oldStudents = {
      all:{
        [5]:{lms_student_id:5, name:"apple"},
        [6]:{lms_student_id:6, name:"banana"},
        [7]:{lms_student_id:7, name:"coconut"},
        [8]:{lms_student_id:8, name:"dragonfruit"},
      }
    };

    const result = studentReducer(oldStudents, action);

    expect(Object.keys(result.all).length).toEqual(8);
    expect(Object.keys(result.all)).toEqual(['1','2','3','4','5','6','7','8']);
  });
});