"use strict";

import React from 'react';

export default (props) => {

  const handleChange = (e) => {
    const files = e.target.files;
    const file = files.length == 1 ? files[0] : null;
    if(file){
      props.uploadPackage(file);
    }
  };

  const inputStyles = {
    display: "none"
  };

  return (
    <label className="c-btn-label" htmlFor="upload">
      <div className="c-btn c-btn--upload">
        <svg className="c-icon-upload" xmlns="http://www.w3.org/2000/svg" width="48" height="48" viewBox="0 0 48 48">
          <path d="M0 0h48v48h-48z" fill="none"/>
          <path className="c-path" d="M38.71 20.07c-1.36-6.88-7.43-12.07-14.71-12.07-5.78 0-10.79 3.28-13.3 8.07-6.01.65-10.7 5.74-10.7 11.93 0 6.63 5.37 12 12 12h26c5.52 0 10-4.48 10-10 0-5.28-4.11-9.56-9.29-9.93zm-10.71 5.93v8h-8v-8h-6l10-10 10 10h-6z"/>
        </svg>
        <input
          id="upload"
          type="file"
          onChange={(e) => handleChange(e)}
          style={inputStyles}/>
        <strong> Upload</strong>
      </div>
    </label>
  );
};